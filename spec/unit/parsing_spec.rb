require 'spec_helper'
describe 'Upton' do 
  describe 'Scraper' do 
    context 'parsing' do 

      before(:all) do 
        @scraper = Upton::Scraper.new '', ''
        @html = %q{
                <!doctype html><html lang="en"><head><meta charset="UTF-8"><title>Document</title></head>
                <body>
                  <h1 class="item"><a href="http://example.com/thing/1">Thing 1</a></h1>
                  <h1 class="item"><a href="http://example.com/thing/2">Thing 2</a></h1>

                  <h2 class="bad-item"><a data-href="http://example.com/thing/xxx">Thing 2</a></h2>
                </body></html>}
      end

      describe '#parse_index' do 
        it 'should return an array' do 
          expect(@scraper.send :parse_index, @html, 'h1#not-actually-existing-element').to be_an Array
        end

        it 'should use Nokogiri to find element(s) within @html::selector' do
          arr = @scraper.send :parse_index, @html, 'h1.item a'
          expect(arr.count).to eq 2
        end

        it 'should return hrefs in found elements' do
          href = @scraper.send( :parse_index, @html, 'h1.item a').first
          expect(href).to eq 'http://example.com/thing/1'
        end

        it 'should currently not allow user to specify actual attribute' do 
          # in cases where links are not inside href attribute, Upton doesn't allow user
          # to specify the attribute
          data_href = @scraper.send( :parse_index, @html, 'h2.bad-item a').first
          expect(data_href).to be_nil
        end
      end


    end
  end
end
