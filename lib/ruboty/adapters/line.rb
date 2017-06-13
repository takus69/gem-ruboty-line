require "rack"
require 'line/bot'
require 'rest-client'

module Line
  module Bot
    class HTTPClient
      def post(url, payload, header = {})
        Ruboty.logger.debug "======= HTTPClient#post ======="
        Ruboty.logger.debug "payload #{payload}"
        Ruboty.logger.debug "FIXIT_URL #{ENV["RUBOTY_FIXIE_URL"]}"
        Ruboty.logger.debug "URI #{url}"
        Ruboty.logger.debug "HEADER#{header}"
        RestClient.proxy = ENV["RUBOTY_FIXIE_URL"] if ENV["RUBOTY_FIXIE_URL"]
        RestClient.post(url, payload, header)
      end
    end
  end
end


module Ruboty module Adapters
	class LINE < Base
		env :RUBOTY_LINE_CHANNEL_ID,     "YOUR LINE BOT Channel ID"
		env :RUBOTY_LINE_CHANNEL_SECRET, "YOUR LINE BOT Channel Secret"
		env :RUBODY_LINE_CHANNEL_TOKEN,  "YOUR LINE BOT Channel Token"
		env :RUBOTY_LINE_ENDPOINT,       "LINE bot endpoint(Callback URL). (e.g. '/ruboty/line'"
		def run
			Ruboty.logger.info "======= LINE#run ======="
			start_server
		end

		def say msg
			Ruboty.logger.info "======= LINE#say ======="

			text = msg[:body]
			to   = msg[:to]

			Ruboty.logger.info "text : #{text}"
			Ruboty.logger.debug "to : #{to}"

			msg = {
				type: 'text',
				text: text
			}

			client.reply_message(
				to,
				msg
			)
		end

		private
		def start_server
			Rack::Handler::Thin.run(Proc.new{ |env|
				Ruboty.logger.info "======= LINE access ======="
				Ruboty.logger.debug "env : #{env}"

				request = Rack::Request.new(env)
				result = on_post request

				[200, {"Content-Type" => "text/plain"}, [result]]
			}, { Port: ENV["PORT"] || "8080" })
		end

		def on_post req
			Ruboty.logger.info "======= LINE#on_post ======="
			Ruboty.logger.debug "request : #{req}"

			return "OK" unless req.post? && req.fullpath == ENV["RUBOTY_LINE_ENDPOINT"]

			body = req.body.read
			Ruboty.logger.debug "request.body : #{body}"
			events = client.parse_events_from(body)
			events.each { |event|
				case event
				when ::Line::Bot::Event::Message
					case event.type
					when ::Line::Bot::Event::MessageType::Text
						Ruboty.logger.debug "text: #{event.message['text']}"
						message = {
							text: event.message['text'],
							to: event['replyToken']
						}
						on_message message
					end
				end
			}

			return ""
		end

		def on_message msg
			Ruboty.logger.info "======= LINE#on_message ======="
			Ruboty.logger.debug "body: #{msg[:text]}"
			Ruboty.logger.debug "to: #{msg[:to]}"
			Ruboty.logger.debug "msg: #{msg}"

			Thread.start {
				robot.receive(
					body: msg[:text],
					from: msg[:to],
					to:   msg[:to],
					message: msg)
			}
		end

		def client
			@client ||= ::Line::Bot::Client.new { |config|
				config.channel_secret = ENV["RUBOTY_LINE_CHANNEL_SECRET"]
				config.channel_token  = ENV["RUBODY_LINE_CHANNEL_TOKEN"]
 			}
		end
	end
end end
