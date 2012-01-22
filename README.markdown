## What is Jenkins-Pullover?

Jenkins-Pullover is a simple daemon that polls a Github project looking for pull requests that require integration. The all pull requests that require building are then scheduled in Jenkins using the remote trigger API.