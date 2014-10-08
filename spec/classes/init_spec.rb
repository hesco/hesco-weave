require 'spec_helper'
describe 'weave' do

  context 'with defaults for all parameters' do
    it { should contain_class('weave') }
  end
end
