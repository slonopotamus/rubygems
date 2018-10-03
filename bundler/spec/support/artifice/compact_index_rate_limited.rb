# frozen_string_literal: true

require File.expand_path("../compact_index", __FILE__)

Artifice.deactivate

class CompactIndexRateLimited < CompactIndexAPI
  class RequestCounter
    def self.init
      @queue ||= Queue.new
    end

    def self.size
      @queue.size
    end

    def self.enq(name)
      @queue.enq(name)
    end

    def self.deq
      @queue.deq
    end
  end

  configure do
    RequestCounter.init
  end

  get "/info/:name" do
    RequestCounter.enq(params[:name])

    begin
      if RequestCounter.size == 1
        etag_response do
          gem = gems.find {|g| g.name == params[:name] }
          CompactIndex.info(gem ? gem.versions : [])
        end
      else
        status 429
      end
    ensure
      RequestCounter.deq
    end
  end
end

Artifice.activate_with(CompactIndexRateLimited)
