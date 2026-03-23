values.yaml

  Some values for the service

values.schema.json

  Schema of the values.yaml file. Can be created automatically with this
  command:

    $ helm plugin install https://github.com/karuppiah7890/helm-schema-gen --verify=false
    $ helm schema-gen values.yaml > values.schema.json

