## To Add New Credentials

```seaweed-s3-config``` secret contains json file which contains details for every user.

Check the sample secret file [here](examples/seaweedfs-s3-config.yaml)

To manage it easily, it is recommended to manage the json file separately and use the following the command to turn it into sealed-secrets:

```shell
kubectl create secret generic seaweedfs-s3-config \
  -n seaweedfs \
  --from-file=seaweedfs_s3_config=s3-config.json \
  --dry-run=client -o yaml \
| kubeseal \
  --format yaml \
  --controller-name sealed-secrets-controller \
  --controller-namespace sealed-secrets \
  --namespace seaweedfs \
  --name seaweedfs-s3-config \
> seaweedfs-s3-config-sealed.yaml
```
