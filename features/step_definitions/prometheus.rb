When(/^I perform the (GET|POST) prometheus rest client with:$/) do | op_type, table |
  opts = opts_array_to_hash(table.raw)
  raise "required parameter 'path' or 'query' is missing" unless opts[:path] or opts[:query]

  # prepare prometheus dns and token
  step %Q{I use the "openshift-monitoring" project}
  prometheus_dns = route("prometheus-k8s").dns
  if opts.has_key? :token
    token = opts[:token]
  else
    token = secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token
  end

  https_opts = {}
  https_opts[:proxy] = env.client_proxy if env.client_proxy
  https_opts[:headers] ||= {}
  https_opts[:headers][:accept] ||= "application/json"
  https_opts[:headers][:content_type] ||= "application/json"
  https_opts[:headers][:authorization] ||= "Bearer #{token}"

  uri = URI.parse("https://" + prometheus_dns + opts[:path])
  uri.query = URI.encode_www_form("query": opts[:query]) if opts[:query]

  @result = BushSlicer::Http.request(url: uri.to_s, **https_opts, method: op_type)
  @result[:parsed] = YAML.load(@result[:response]) if @result[:success]
end
