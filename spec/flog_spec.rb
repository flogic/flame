require File.dirname(__FILE__) + '/spec_helper.rb'
require 'flog'

describe Flog do
  describe 'when initializing' do
    it 'should allow no arguments' do
      lambda { Flog.new 'bogus' }.should raise_error(ArgumentError)
    end
    
    it 'should succeed if given no arguments' do
      lambda { Flog.new }.should_not raise_error
    end
  end
  
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
  
  describe "when flogging a list of files" do
    before :each do
      @flog = Flog.new
    end
    
    describe 'when stdin is specified as input' do
      it 'should not raise an exception'
      
      it 'should do something useful'
    end
    
    describe 'when files are specified' do
      describe 'when some of the files do not exist' do
        before :each do
          @files = [ __FILE__, '/asdfasfas/asdfasdfasdfasd' ]
        end
        
        it 'should raise an error about the missing files' do
          lambda { @flog.flog_files(@files) }.should raise_error(Errno::ENOENT)
        end       
      end
      
      describe 'when all the files exist' do
        before :each do
          @files = [ __FILE__ ]
        end
        
        it 'should not raise an exception' do
          lambda { @flog.flog_files(@files) }.should_not raise_error
        end

        it 'should do something useful'        
      end
    end
    
    describe 'when no files are specified' do
      it 'should not raise an exception' do
        lambda { @flog.flog_files }.should_not raise_error
      end
      
      it 'should do nothing'
    end
  end
end