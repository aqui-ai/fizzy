require "net/http"

class Github::Client
  BASE_URL = "https://api.github.com"

  def initialize(token)
    @token = token
  end

  # GitHub's issues endpoint also returns pull requests; filter them out.
  def issues(full_name, max_pages: 5)
    get_all("#{BASE_URL}/repos/#{full_name}/issues?state=all&per_page=100", max_pages)
      .reject { |issue| issue.key?("pull_request") }
  end

  def pull_requests(full_name, max_pages: 5)
    get_all("#{BASE_URL}/repos/#{full_name}/pulls?state=all&per_page=100", max_pages)
  end

  private
    def get_all(url, max_pages)
      results = []

      max_pages.times do
        response = get(url)
        break unless response.is_a?(Net::HTTPSuccess)

        results.concat(Array(JSON.parse(response.body)))
        break unless url = next_page(response["Link"])
      end

      results
    end

    def next_page(link_header)
      link_header && link_header[/<([^>]+)>;\s*rel="next"/, 1]
    end

    def get(url)
      uri = URI(url)
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{@token}"
      request["Accept"] = "application/vnd.github+json"
      request["User-Agent"] = "Fizzy"

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
    end
end
