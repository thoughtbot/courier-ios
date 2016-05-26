/**
 Represents a Courier environment which determines which APNs environment to use.

 Courier will use the APNs staging environment for `development` and the APNs production environment for `production`.

 - attention:
  Be sure to use the appropriate environment.

  Builds of your app signed with a development certificate can only receive notifications from the APNs staging environment. These builds should be using `Environment.Development`.

  Similarly builds of your app signed with a distribution certificate can only receive notifications from the APNs production environment. Use `Environment.Production` for these builds.
*/
public enum Environment: String {
  /**
   The Courier development environment. Only builds signed with a development certificate can receive push notifications when using this environment.
  */
  case Development = "development"

  /**
   The Courier production environment. Only builds signed with a distribution certificate can receive push notifications when using this environment.
  */
  case Production = "production"
}
