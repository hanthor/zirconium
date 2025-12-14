image := env("IMAGE_FULL", "zirconium:latest")
base_dir := env("BUILD_BASE_DIR", ".")
filesystem := env("BUILD_FILESYSTEM", "ext4")

iso $image=image:
    #!/usr/bin/env bash
    mkdir -p output
    IMAGE_CONFIG="$(mktemp)"
    export IMAGE_FULL="${image}"
    envsubst < ./config.toml > "${IMAGE_CONFIG}"
    sudo podman pull "${image}"
    sudo podman run \
        --rm \
        -it \
        --privileged \
        --pull=newer \
        --security-opt label=type:unconfined_t \
        -v "${IMAGE_CONFIG}:/config.toml:ro" \
        -v ./output:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        quay.io/centos-bootc/bootc-image-builder:latest \
        --type iso \
        --use-librepo=True \
        "${image}"

rootful $image=image:
    #!/usr/bin/env bash
    podman image scp $USER@localhost::$image root@localhost::$image

bootc *ARGS:
    sudo podman run \
        --rm --privileged --pid=host \
        -it \
        -v /sys/fs/selinux:/sys/fs/selinux \
        -v /etc/containers:/etc/containers:Z \
        -v /var/lib/containers:/var/lib/containers:Z \
        -v /dev:/dev \
        -v "{{base_dir}}:/data" \
        --security-opt label=type:unconfined_t \
        "{{image}}-rechunked" bootc {{ARGS}}

disk-image $base_dir=base_dir $filesystem=filesystem:
    #!/usr/bin/env bash
    if [ ! -e "${base_dir}/bootable.img" ] ; then
        fallocate -l 20G "${base_dir}/bootable.img"
    fi
    just bootc install to-disk --via-loopback /data/bootable.img --filesystem "${filesystem}" --wipe

run-vm $base_dir=base_dir:
    #!/usr/bin/env bash
    set -eoux pipefail

    image_file="${base_dir}/bootable.img"

    if [[ ! -f "${image_file}" ]]; then
        echo "Image not found: ${image_file}"
        echo "Please run 'just disk-image' first."
        exit 1
    fi

    # Determine an available port to use
    port=8006
    while grep -q :${port} <<< $(ss -tunalp); do
        port=$(( port + 1 ))
    done
    echo "Using Port: ${port}"
    echo "Connect to http://localhost:${port}"

    # Set up the arguments for running the VM
    run_args=()
    run_args+=(--rm --privileged)
    run_args+=(--pull=newer)
    run_args+=(--publish "127.0.0.1:${port}:8006")
    run_args+=(--env "CPU_CORES=4")
    run_args+=(--env "RAM_SIZE=4G")
    run_args+=(--env "DISK_SIZE=64G")
    run_args+=(--env "TPM=Y")
    run_args+=(--env "GPU=Y")
    run_args+=(--device=/dev/kvm)
    # Use absolute path for reliability
    run_args+=(--volume "$(readlink -f "${image_file}")":/boot.img)
    run_args+=(docker.io/qemux/qemu)

    function sudoif(){
        if [[ "${UID}" -eq 0 ]]; then
            "$@"
        elif [[ "$(command -v sudo)" && -n "${SSH_ASKPASS:-}" ]] && [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
            /usr/bin/sudo --askpass "$@" || exit 1
        elif [[ "$(command -v sudo)" ]]; then
            /usr/bin/sudo "$@" || exit 1
        else
            exit 1
        fi
    }

    # Run the VM and open the browser to connect
    sudoif podman run "${run_args[@]}" &
    # Wait a moment for container to start
    sleep 2
    xdg-open "http://localhost:${port}" || echo "Open http://localhost:${port} in your browser"
    fg "%podman"

quick-iterate:
    #!/usr/bin/env bash
    just build-components
    podman build -t zirconium:latest --no-cache . --build-arg BUILD_FLAVOR="${BUILD_FLAVOR:-}" --build-arg REPOSITORY="${REPOSITORY:-localhost}"
    just rootful
    just rechunk
    just disk-image

quick-iterate-experimental:
    #!/usr/bin/env bash
    podman build --jobs $(nproc) -f Containerfile.experimental -t zirconium:latest . --build-arg BUILD_FLAVOR="${BUILD_FLAVOR:-}" 
    just rootful
    just rechunk
    just disk-image

rechunk $src_image="zirconium" $src_tag="latest" $dst_tag=(src_tag + "-rechunked"):
    #!/usr/bin/env bash
    set -euxo pipefail

    local_src="localhost/{{ src_image }}:{{ src_tag }}"
    remote_src="{{ src_image }}:{{ src_tag }}"
    # Always use localhost/ prefix for destination to match workflow expectations
    dst="localhost/{{ src_image }}:{{ dst_tag }}"
    src=""

    function sudoif(){
        if [[ "${UID}" -eq 0 ]]; then
            "$@"
        elif [[ "$(command -v sudo)" && -n "${SSH_ASKPASS:-}" ]] && [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
            /usr/bin/sudo --askpass "$@" || exit 1
        elif [[ "$(command -v sudo)" ]]; then
            /usr/bin/sudo "$@" || exit 1
        else
            exit 1
        fi
    }

    echo "Checking for source image..."
    # Check root's storage for the image
    if sudoif podman image exists "${local_src}"; then
        src="${local_src}"
        echo "Found source image: ${src}"
    elif sudoif podman image exists "${remote_src}"; then
        src="${remote_src}"
        echo "Found source image: ${src}"
    else
        echo "Error: Image not found in root storage: {{ src_image }}:{{ src_tag }} (or localhost prefixed)." >&2
        echo "Available images:"
        sudoif podman images
        exit 1
    fi

    echo "Starting rechunk: ${src} -> ${dst}"
    echo "This may take several minutes..."

    # Run rechunk with explicit logging
    sudoif podman run \
        --rm \
        --privileged \
        --pull=never \
        --security-opt=label=disable \
        --mount type=tmpfs,destination=/var/tmp \
        -v /var/lib/containers:/var/lib/containers \
        --entrypoint=/usr/libexec/bootc-base-imagectl \
        "${src}" \
        rechunk "${src}" "${dst}"

    echo "Rechunk process completed, verifying output..."

    # Verify the rechunked image was created
    if sudoif podman image exists "${dst}"; then
        echo "✓ Rechunked image successfully created: ${dst}"
    else
        echo "✗ Warning: Rechunked image not found at expected location: ${dst}"
        echo "Available images:"
        sudoif podman images
        exit 1
    fi 

build-components:
    #!/usr/bin/env bash
    chmod +x build_files/build_components.py
    REGISTRY="localhost" ./build_files/build_components.py

