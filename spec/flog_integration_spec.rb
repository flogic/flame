require File.dirname(__FILE__) + '/spec_helper.rb'
require 'flog'
require 'sexp_processor'

describe Flog do
  before :each do
    @flog = Flog.new
  end

  describe 'flog_files' do
    def fixture_files(paths)
      paths.collect do |path|
        File.expand_path(File.dirname(__FILE__) + '/../spec_fixtures/' + path)
      end
    end
    
    before :each do
      @flog = Flog.new
    end
    
    describe 'when given empty input' do
      before :each do
        @files = ['/empty/empty.rb']
      end
    
      it 'should not fail when flogging the given input' do
        lambda { @flog.flog_files(fixture_files(@files)) }.should_not raise_error
      end
    end
  
    describe 'when given a simple file' do
      before :each do
        @files = ['/simple/simple.rb']
      end
    
      it 'should not fail when flogging the given input' do
        lambda { @flog.flog_files(fixture_files(@files)) }.should_not raise_error
      end
    end
  
    describe 'when given a directory of files' do
      before :each do
        @files = ['/directory/']      
      end
    
      it 'should not fail when flogging the given input' do
        lambda { @flog.flog_files(fixture_files(@files)) }.should_not raise_error
      end
    end
  
    describe 'when given a collection of files' do
      before :each do
        @files = ['/collection/']      
      end

      it 'should not fail when flogging the given input' do
        lambda { @flog.flog_files(fixture_files(@files)) }.should_not raise_error
      end
    end
  end
end