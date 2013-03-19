# coding: utf-8
require 'nokogiri'
require 'open-uri'
namespace :parse do

  desc "get tv_dramas pre release resources from  yyets.com"

  task :pre_release => :environment do
    year = 2013
    months = [01, 02, 03, 04]
    init_n = 1
    months.each do |month|
      begin
        dom = Nokogiri::HTML open(remote_url(:year => year, :month => month))    
        dom.at('table.playTime_tv').css('td.ihbg, td.cur').css('dl').each_with_index do |ele, i|
          d =  ele.at('dt').content.scan(/\d{1,2}/).first.to_i
          datetime = "#{year}#{month}#{ '%02d' % d }"          
          dd_dom = ele.css('dd').each_with_index do |_ele, _i|
            opts = {}
            link = _ele.at('a')
            if link.present?
              tv_name = link.css('.fa1').first.content
              pre_v = link.css('.fa1').last.content
              opts[:season] = pre_v.scan(/S\d{2,2}/).first || 'S01'
              opts[:episode] = pre_v.scan(/E\d{2,2}/).first || 'E01'
              opts[:release_date] = datetime.to_datetime
              tv_drama = TvDrama.any_of(:tv_name => /#{tv_name}/).first
              if tv_drama.present?
                if tv_drama.pre_releases.where(season: opts[:season], episode: opts[:episode]).blank?
                  tv_drama.pre_releases.create!(opts)
                  init_n += 1
                  p "create #{init_n}"
                end
              end
            end
          end
        end
      rescue Exception => e
        p e.inspect
      end
    end
  end

  def remote_url(time)
    time[:year] ||= 2012
    time[:month] ||= 10
    "http://www.yyets.com/php/tv/schedule/index/year/#{time[:year]}/month/#{time[:month]}"
  end
end
