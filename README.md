# Okta Auth Proxy

The idea is that you run this along-side an nginx instance, and it'll handle authentication for you for an application or page that doesn't understand SAML or okta.

## Integrating with Okta

If you're using Okta, you'll need to create a custom SAML application that uses the *Single sign on URL* `[your-domain]/auth/saml/callback`.

# Configuration

Set the following environment variables

* `SSO_TARGET_URL`: the target url specified in okta
* `SSO_ISSUER`: the accepted audience in okta
* `PROXY_TARGET`: the address of the target application you are authing for
* `CERT_PATH`: Path to the certificate provided by Okta
* `COOKIE_DOMAIN`: The domain to use for the cookie

If okta authentication succeeds, a cookie will be created in the scope of `COOKIE_DOMAIN` and stored for the session. All requests are proxied through proxy target if authentication succeeds. Note that `COOKIE_DOMAIN` must be set to the same hostname you access your virtual host on.

The proxy target should be set as an internal server in nginx, so that it can only be accessed through a local referral. See the example nginx configuration provided

The following variables are optional:

* `AUTH_DOMAIN`: the local address of this authentication app (change if not 'localhost')
* `COOKIE_SECRET`: a secure random secret for the session cookie. A random value will be generated at runtime when not provided. If you need to avoid reauthenticating each time okta-auth-proxy is restarted for some reason, set this to a fixed value.
* `DEBUG`: set this to anything to debug logging

**Note:** Ensure the protocol in okta matches the protocol of your app (http/https)

```bash
export SSO_TARGET_URL=https://company.okta.com/app/company_project_1/hXk5d47tkNkB0x7/sso/saml
export CERT_PATH="/path/to/okta.cert"
export COOKIE_DOMAIN="example.com"
export PROXY_TARGET=http://127.0.0.1:7000
bundle exec okta-auth-proxy serve
```

# Credits

This was inspired by smashing the ideas from projects together:

* https://antoineroygobeil.com/blog/2014/2/6/nginx-ruby-auth/
* https://github.com/ThoughtWorksInc/okta-samples/tree/master/okta-ruby-sinatra
