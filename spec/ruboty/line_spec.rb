require 'spec_helper'

describe Ruboty::Line do
  it 'has a version number' do
    expect(Ruboty::Line::VERSION).not_to be nil
  end
end

describe Ruboty::Adapters do
  it 'initilizes ruboty-line' do
    mod = Ruboty::Adapters::LINE.new(1)
    mod.run
    msg = {to: "takus", body: "line test"}
    mod.say msg
  end
end
