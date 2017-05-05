require 'sinatra'
require 'logger'
require 'okta-auth-proxy/auth'

module OktaAuthProxy
  class ProxyApp < Sinatra::Base
    register OktaAuthProxy::OktaAuth

    def initialize
      super
      @logger = Logger.new(STDOUT)
      @logger.progname = 'okta-auth-proxy'
      @logger
    end

    def extend_session
      if session[:logged]
        current_time = Time.new
        session[:expire] = current_time.to_i + ENV.fetch('SESSION_EXPIRE', 1800).to_i
      end
    end

     # Block that is called back when authentication is successful
    [:get, :post, :put, :head, :delete, :options, :patch, :link, :unlink].each do |verb|

      send verb, '/*' do
        pass if request.host == ENV.fetch('AUTH_DOMAIN', 'localhost')
        pass if request.path == '/auth/saml/callback'
        pass if request.path == '/auth/failure'

        if request.host != OktaAuth.cookie_domain
          @logger.warn "Request host (#{request.host}) and COOKIE_DOMAIN (#{OktaAuth.cookie_domain}) " +
            "do not match. Cookies will not be set or readable. Check your COOKIE_DOMAIN value."
        end

        protected!
        # If authorized, serve request
        url = authorized?(request.host)
        if url
          headers "X-Remote-User" => session[:uid]
          # Conserve the request method
          if request.referrer and not request.referrer.include? '.okta.com'
            headers "X-Reproxy-Method" => request.request_method
          end
          headers "X-Reproxy-URL" => File.join(url, request.fullpath)
          headers "X-Accel-Redirect" => "/reproxy"
          extend_session
          redirect to('http://localhost'), 307
        end
      end

      send verb, '/auth/:name/callback' do
        auth = request.env['omniauth.auth']
        session[:logged] = true
        session[:provider] = auth.provider
        session[:uid] = auth.uid
        session[:name] = auth.info.name
        session[:email] = auth.info.email
        if request.env.has_key? 'HTTP_X_FORWARDED_FOR'
          session[:remote_ip] = request.env['HTTP_X_FORWARDED_FOR']
        else
          session[:remote_ip] = request.env['HTTP_X_REAL_IP']
        end
        extend_session
        redirect to(params[:RelayState] || '/'), 307
      end

      send verb, '/auth/failure' do
        'Login failed'
      end
    end
  end
end
