# Fetch the Docker images the integration tests run on.
#
# `docker run` pulls a missing image implicitly, so a transient registry
# problem (rate limiting, a 5xx, a dropped connection) aborts the whole task.
# The CI matrix starts dozens of jobs at once and every one of them pulls its
# images, which makes hitting such a hiccup a regular occurrence: a handful of
# otherwise healthy jobs fail on `docker run` while the rest of the matrix
# passes on the same commit.
#
# Pulling explicitly beforehand turns that into something we can retry, and
# leaves `docker run` with nothing left to fetch.
module DockerImage
  ATTEMPTS = 3
  FIRST_INTERVAL = 15 # seconds, doubled after each failed attempt

  module_function

  def pull(image)
    interval = FIRST_INTERVAL

    ATTEMPTS.times do |attempt|
      return if system('docker', 'pull', image)

      remaining = ATTEMPTS - attempt - 1
      raise "failed to pull #{image} after #{ATTEMPTS} attempts" if remaining.zero?

      $stderr.puts "docker pull #{image} failed (attempt #{attempt + 1}/#{ATTEMPTS}), retrying in #{interval} seconds..."
      sleep interval
      interval *= 2
    end
  end
end
