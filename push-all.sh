#!/bin/bash

docker login -u buildchimp
for c in vrutkovs/koji-dojo-hub vrutkovs/koji-dojo-client; do
	dev="${c}:dev"
	echo "Renaming $c with :dev tag"
	docker tag -f $c $dev

	echo "Pushing: $dev"
	docker push $dev
done
