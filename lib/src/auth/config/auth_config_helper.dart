const _kAwsAppClientId = String.fromEnvironment(
  'AWS_APP_CLIENT_ID',
);
const _kAwsUserPoolId = String.fromEnvironment(
  'AWS_USER_POOL_ID',
);
const _kAwsRegion = String.fromEnvironment(
  'AWS_REGION',
);

//
class AuthConfigHelper {
  //
  static String getConfigurationString() => ''' {
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "IdentityManager": {
          "Default": {}
        },
        "CognitoUserPool": {
          "Default": {
            "AppClientId": "$_kAwsAppClientId",
            "PoolId": "$_kAwsUserPoolId",
            "Region": "$_kAwsRegion"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH"
          }
        }
      }
    }
  }
}''';
}
