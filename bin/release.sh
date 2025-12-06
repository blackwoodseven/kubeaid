#!/bin/bash

# Run this when the helm chart update PR is merged into master

NEW_TAG=$(cat VERSION)

git tag -a "$NEW_TAG" -m "Kubeaid Release $NEW_TAG"
git push orgin --tags
