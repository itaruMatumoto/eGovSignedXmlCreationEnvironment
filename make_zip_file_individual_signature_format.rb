require 'fileutils'
require 'zip'
require "cgi"
require 'date' 
require 'kiji'

# 署名ファイル、パスワードを定義する
Key = "./証明書/e-GovEE01_sha2.pfx"
password = "gpkitest"

# 入出力先パスを定義する
input_base_path = "./zip_data/indivisual/in/"
output_base_path = "./zip_data/indivisual/out/"

# 出力先のフォルダ、ファイル等を消す
Dir.glob("#{output_base_path}/*") do |f|
  FileUtils.rm_r(f)
end

# 入出力データのファイルパスを定義する
Procedure = Struct.new(:folder, :kousei_xml, 
                       :config_info_appl_xml, :application_xml, 
                       :config_info_appl_xml_2, :application_xml_2)
proc = Procedure.new("950A102200039000(1)","kousei.xml",
                     "kousei20200716142110000.xml","950A10220003900001_01.xml",
                     "kousei20200716142115000.xml","950A10220003900002_01.xml")

input_path = "#{input_base_path}/#{proc.folder}"
output_path = "#{output_base_path}/#{proc.folder}"

# 申請フォルダを作成する
FileUtils.mkdir_p(output_path)

# Zipper生成
pkcs12 = OpenSSL::PKCS12.new(File.open(Key, "rb"),password)
zipper = Kiji::Zipper.new() do |s|
  s.cert = pkcs12.certificate
  s.private_key = pkcs12.key
end

# 申請書１に対する構成情報XMLに対して署名を行う
signed_xml_path = "#{input_path}/#{proc.config_info_appl_xml}"
style_file_path = ["#{input_path}/#{proc.application_xml}"]
signer = zipper.sign(signed_xml_path, style_file_path)

# 署名付きxmlを書き出す
File.write("#{output_path}/#{proc.config_info_appl_xml}", signer.to_xml)

# 申請書２に対する構成情報XMLに対して署名を行う
signed_xml_path_2 = "#{input_path}/#{proc.config_info_appl_xml_2}"
style_file_path_2 = ["#{input_path}/#{proc.application_xml_2}"]
signer = zipper.sign(signed_xml_path_2, style_file_path_2)

# 署名付きxmlを書き出す
File.write("#{output_path}/#{proc.config_info_appl_xml_2}", signer.to_xml)

# コピーする申請書XML、添付ファイルをリスト化する
copy_files_path = ["#{input_path}/#{proc.kousei_xml}", style_file_path, style_file_path_2]

# 申請書XML、添付ファイルをコピー、リストを空にする
copy_files_path.each do |f|
  FileUtils.cp(f, output_path)
end

# 出力先リストをzipに固める
zipper.write_zip(output_base_path, output_base_path + "apply_data.zip")
