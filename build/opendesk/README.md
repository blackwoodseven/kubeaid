# Opendesk setup


## Installation

1. Basic requirements are - https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/develop/docs/requirements.md#tldr

2. We need to have the helm version less than `3.18.0`. We have done our testing with helm version as `3.17.4`

3. In your cluster the Storage class you are using MUST have sticky bit set. Its the limitation of `openproject`.
Ref - https://github.com/opf/helm-charts/blob/main/charts/openproject/templates/_helpers.tpl#L90

NOTE: We can't provide the SC name right now in opendesk via values file. So, it will always pick up the default one.

4. Using https://easydmarc.com/tools/dkim-record-generator - create a key pair for domain using which you will be sending the mail with selector as default and key length as 4096.
There you will see:

```
Publish the following DNS TXT record on default ._domainkey.$domain subdomain
```
add that in your DNS config tool.

Copy the private key and create a secret named `opendesk-dkimpy-milter` from that.

## Run the build script

The build script needs one variable kubeaid-config repo path which contains the values file.
Sample values [file](./examples/values.yaml)

NOTE: path needs to be an absolute path which means you need to provide the entire path. Ensure the values file is named as `values-opendesk.yaml`

```bash
./build.sh $kubaid-config-values-file-directory-path
```

For eg - the kubeaid-config values file directory path can be like `kubeaid-config/k8s/$clustername/argocd-apps` 

Once the script runs it will generate the following - 
- All the core apps needed by opendesk apps will be generated in `kubeaid-config/k8s/$clustername/opendesk-essentials/opendesk-essentials.yaml`. This needs to be synced first.
- Rest of the apps like `mail`, `chat` etc. will be generated in `kubeaid-config/k8s/$clustername/opendesk/mail/mail.yaml`, `kubeaid-config/k8s/$clustername/opendesk/chat/chat.yaml` respectively

*Note* - Chat, webmail etc applications requires users of type `opendesk-user` to be created.

More info on opendesk services can be found [here](./docs/opendesk-services-description.md)


## Adding missing configuration using Custom Go Template Values Files

Sometimes some value file configurations maybe missing for certain application charts, f.ex for openproject application, [tmpVolumesStorageClassName](https://github.com/opf/helm-charts/blob/22758c9363583a71a289b36a75c3b893f9a3e763/charts/openproject/values.yaml#L540) option wasn't in the helmfile app values files found in [./versions/v1.6.0/helmfile/apps/openproject/](./versions/v1.6.0/helmfile/apps/openproject/). So the following was done to add this configuration -
- create a custom go template values file (`values-<app>.yaml`) in the `value-files` directory as done [here](./value-files/values-openproject.yaml.gotmpl), with the required configuration. 
- add default values for the configuration in the [default values file](./default-values/values.yaml)
- in the [default values file](./default-values/values.yaml) add the new custom go template values file in the helmfile app release as shown below

```
customization:
  release:
    <app>:
      - "../../../../../value-files/values-<app>.yaml.gotmpl"
```

Follow the above to add missing configurations in the helmfile opendesk apps.