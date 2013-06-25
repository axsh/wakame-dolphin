require "net/http"
require "uri"

module WebRequestHelper
  def get(path, params)
    uri = build_uri(path)
    net = Net::HTTP::Get.new(uri.request_uri, params[:headers])
    request(net, uri)
  end

  def post(path, params)
    uri = build_uri(path)
    net = Net::HTTP::Post.new(uri.request_uri, params[:headers])
    net.body = params[:body]
    request(net, uri)
  end

  def delete(path, params)
    uri = build_uri(path)
    net = Net::HTTP::Delete.new(uri.request_uri, params[:headers])
    request(net, uri)
  end

  private

  def build_uri(path)
    server = Dolphin.settings['server']
    endpoint = "http://#{server['host']}:#{server['port']}"
    URI.parse(endpoint + path)
  end

  def request(net, uri)
    http = Net::HTTP.new(uri.host, uri.port)
    # http.set_debug_output $stderr
    http.start do |h|
      response = h.request(net)
      JSON.parse(response.body)
    end
  end
end