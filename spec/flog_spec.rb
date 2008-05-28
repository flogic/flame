require File.dirname(__FILE__) + '/spec_helper.rb'
require 'flog'

describe Flog do
  describe 'after initializing' do
    before :each do
      @flog = Flog.new
    end

    it 'may need to verify more state than these specs currently do'
    
    it 'should return an SexpProcessor' do
      @flog.should be_a_kind_of(SexpProcessor)
    end
    
    it 'should be initialized like all SexpProcessors' do
      # less than ideal means of insuring the Flog instance was initialized properly, imo -RB
      @flog.context.should == []  
    end
    
    it 'should not have any calls yet' do
      @flog.calls.should == {}
    end
  end
end