package main

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/secretsmanager"
)

func ListKeys(svc *secretsmanager.SecretsManager) ([]string, error) {
	input := &secretsmanager.ListSecretsInput{}
	output := []string{}

	results, err := svc.ListSecrets(input)

	if err != nil {
		return output, err
	}

	for _, secret := range results.SecretList {
		output = append(output, aws.StringValue(secret.Name))
	}

	return output, err
}

func GetSecretValue(svc *secretsmanager.SecretsManager, key string) (string, error) {
	input := &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(key),
	}

	results, err := svc.GetSecretValue(input)

	if err != nil {
		return "", nil
	}

	return aws.StringValue(results.SecretString), err
}
