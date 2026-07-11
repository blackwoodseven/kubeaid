# HAMi

[HAMi](https://project-hami.io) (Heterogeneous AI Computing Virtualization
Middleware) is a CNCF Incubating project that provides GPU sharing and
virtualization for Kubernetes. It lets multiple pods share a single physical
GPU by slicing device memory and compute in software, which also works on
consumer/workstation GPUs where MIG is not available.

Upstream chart: [https://project-hami.github.io/HAMi/](https://github.com/Project-HAMi/HAMi)

## Usage

- Label the nodes whose GPUs should be managed by HAMi:

  ```sh
  kubectl label node <gpu-node> gpu=on
  ```

- Request a fractional GPU from a pod:

  ```yaml
  resources:
    limits:
      nvidia.com/gpu: 1        # number of vGPUs
      nvidia.com/gpumem: 3000  # device memory in MiB (optional)
      nvidia.com/gpucores: 30  # percent of GPU compute (optional)
  ```

## Configuration

All values are kept at upstream defaults; override them under the `hami:`
key in your cluster's values file. See the
[upstream values](https://github.com/Project-HAMi/HAMi/blob/master/charts/hami/values.yaml)
and the [HAMi docs](https://project-hami.io/docs/) for details.

Notes:

- The scheduler runs as a kube-scheduler extender; nothing needs to change
  in existing workloads that request whole GPUs.
- The NVIDIA device plugin shipped by HAMi replaces the stock
  `nvidia-device-plugin` on labelled nodes — do not run both on the same node.
- Requires the NVIDIA driver and `nvidia-container-toolkit` on GPU nodes.
