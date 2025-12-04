# Update kubeaid apps managed via argocd

* This scripts need to be run manually during the service or a day before and raise the PR and get it to merged.
* The script basically point to the given tag as a flag to the script
* Make sure the same tag is used for the entire service window cycle **DO NOT: use latest/recent tag in the middle of service window cycle**

If a customer chooses to deploy the Helm chart using different application names—such as **traefik-external** or **traefik-internal**—we must manually add each of these names to:

```
k8s/<cluster-name>/kube-prometheus/argocd-application-prometheus-rulesprometheusRuleExample.yaml
```

This has to be done manually because a single Helm chart can be reused to deploy multiple applications under different names.
For example, in Obmondo, *traefik* is deployed as **external**, **private**, etc., each requiring its own entry.


## Update the tags for a cluster
- should be run at this folder level `/kubeaid-config-enableit/k8s/`
```sh
docker run -it  -v $(pwd):/workspace -v ../../KubeAid:/KubeAid harbor.obmondo.com/obmondo/kubeaid-update-apps:1.0.0 /KubeAid/bin/update-kubeaid-argocd-app.sh -c <cluster-name> -r <tag-for-the-current-window-cycle>
```
