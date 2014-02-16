require 'spec_helper'
require 'upton'

describe 'Upton' do 
  describe 'Scraper' do 
    context 'scraping paginated index pages' do 
      describe '#next_index_page_url' do 

        let(:page_url){ 'http://www.propublica.org/search.php?q=test' }
        let(:pagination_param){ 'page' }
        # let(:unpaginated_scraper){ Upton::Scraper.index(@page_url, "a", {:paginated => false, :pagination_param => pagination_param})}
        let(:u){ Upton::Scraper.index(@page_url, "a", {:paginated => true, :pagination_param => pagination_param}) }

        #obsolete, since get_index_pages controls whether next_index_page_url gets called
        # it "should return an empty string by default" do
        #   expect(u.next_index_page_url(page_url, pagination_param, 1)).to be_empty
        # end

        context "@paginated is true" do
          it "should use use pagination_param to specify the current page in the query string" do
            expect(u.next_index_page_url(page_url, pagination_param, 2)).to eq "#{page_url}&#{pagination_param}=2"
          end

          # outdated, since max_pages is tested in get_index_pages
          # it "should return an empty string if pagination_index argument is greater than @pagination_max_pages" do
          #   u.pagination_max_pages = 10
          #   expect(u.next_index_page_url(page_url, 11)).to be_empty
          # end
        end
      end
    end
  end
end
