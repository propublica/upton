require 'spec_helper'
require 'upton'

describe 'Upton' do 
  describe 'Scraper' do 
    context 'scraping paginated index pages' do 
      describe '#next_index_page_url' do 

        let(:page_url){ 'http://www.propublica.org/search.php?q=test' }
        let(:u){ Upton::Scraper.new(@page_url, "a") }

        it "should return an empty string by default" do
          expect(u.next_index_page_url(page_url, 1)).to be_empty
        end

        context "@paginated is true" do

          before do
            u.paginated = true
          end

          it "should use use @pagination_param to specify the current page in the query string" do
            u.pagination_param = 'current_page'
            expect(u.next_index_page_url(page_url, 2)).to eq "#{page_url}&#{u.pagination_param}=2"
          end

          it "should return an empty string if pagination_index argument is greater than @pagination_max_pages" do
            u.pagination_max_pages = 10
            expect(u.next_index_page_url(page_url, 11)).to be_empty
          end
        end
      end
    end
  end
end
