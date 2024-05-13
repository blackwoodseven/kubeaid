# AWS Setup

* Get AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY (You can create a new service account)
* Login on AWS console, go to IAM and create User
* export these variables

  ```sh
    export AWS_REGION=us-east-1
    export AWS_ACCESS_KEY_ID=<your-access-key>
    export AWS_SECRET_ACCESS_KEY=<your-secret-access-key>

    export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm bootstrap credentials encode-as-profile)
  ```
