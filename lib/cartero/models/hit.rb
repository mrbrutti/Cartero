# Documentation for Hit
class Hit
  include MongoMapper::Document

  key :ip, 					String
  key :port, 				String
  key :domain,			String
  key :path,				String
  key :user_agent, 	String
  key :ua_comp,			String
  key :ua_os, 			String
  key :ua_browser, 	String
  key :ua_engine,		String
  key :ua_platform,	String
  key :ua_lang,			String
  key :forwarded, 	Boolean
  key :data, 				Hash

  timestamps!

  belongs_to :user
end
