require 'spec_helper'
require 'upton'

describe 'Upton' do 
  describe '#resolve_url' do 

    before(:each) do 
      @page_url = 'http://www.propublica.org/'
      @u = Upton::Scraper.new(@page_url, "a")
    end

    context 'arguments' do 
      it 'should raise ArgumentError without 2 arguments' do 
        expect{@u.send(:resolve_url, 'x')}.to raise_error ArgumentError
      end

      it 'should raise ArgumentError if either argument is nil' do 
        # ArgumentError is raised through URI factory, btw
        expect{@u.send(:resolve_url, 'x', nil)}.to raise_error ArgumentError
        expect{@u.send(:resolve_url, nil, 'y')}.to raise_error ArgumentError
      end

      it 'should raise ArgumentError if arguments are not a String or URI' do 
        expect{@u.send(:resolve_url, 'http://1.com', 1)}.to raise_error ArgumentError
        expect{@u.send(:resolve_url, {some:'x'}, @page_url)}.to raise_error ArgumentError
      end

      it 'should raise ArgumentError if second arg (page_url) is not absolute' do 
        expect{@u.send(:resolve_url, '/path', '/dir')}.to raise_error ArgumentError
      end
    end

    context 'absolute path resolution' do 


      context 'when first arg, :href, is already absolute' do 
        it 'should be idempotent' do 
          expect(@u.send(:resolve_url, 'http://propublican.org/', @page_url)).to eq 'http://propublican.org/'
        end

        it 'should respect scheme of @page_url when //absolute path used' do 
          expect(@u.send(:resolve_url, '//some.org/', 'https://secure.org')).to eq 'https://some.org/'
        end
      end

      context 'when first arg is relative' do 
        it 'should return @page_url when first arg is empty' do 
          expect(@u.send(:resolve_url, '', @page_url)).to eq @page_url
        end

        it 'should return #hash page anchor ' do 
          expect(@u.send(:resolve_url, '#bang', @page_url)).to eq 'http://www.propublica.org/#bang'
        end

        it 'should return query params' do           
          expect(@u.send(:resolve_url, '?q=1', @page_url)).to eq 'http://www.propublica.org/?q=1'
        end

        it 'should append a root-level path to host' do 
          expect(@u.send(:resolve_url, '/pages', @page_url)).to eq 'http://www.propublica.org/pages'
        end

        it 'should append a subdir path to host' do 
          expect(@u.send(:resolve_url, 'dir', @page_url)).to eq 'http://www.propublica.org/dir'
        end

        it 'should append a subdir path to host w/o a trailing slash' do 
          expect(@u.send(:resolve_url, 'dir', @page_url.chomp('/'))).to eq 'http://www.propublica.org/dir'
        end

        it 'should append a subdir path to existing path' do 
          expect(@u.send(:resolve_url, 'dir', URI.join(URI(@page_url).to_s, URI('/main/').to_s ))
                  ).to eq 'http://www.propublica.org/main/dir'
        end
      end
    end
  end
end