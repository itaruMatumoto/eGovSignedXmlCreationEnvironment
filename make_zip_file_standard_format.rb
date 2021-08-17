require 'fileutils'
require 'zip'
require "cgi"
require 'date' 
require 'kiji'

# 署名ファイル、パスワードを定義する
Key = "./証明書/e-GovEE01_sha2.pfx"
password = "gpkitest"

# 入出力先パスを定義する
input_base_path = "./zip_data/standard/in/"
output_base_path = "./zip_data/standard/out/"

# 出力先のフォルダ、ファイル等を消す
Dir.glob("#{output_base_path}/*") do |f|
  FileUtils.rm_r(f)
end

# 入出力データのファイルパスを定義する
Procedure = Struct.new(:folder, :kousei_xml, :application_xml, :attachment_file)
proc = Procedure.new("900A010200001000(1)","kousei.xml","900A01020000100001_01.xml","添付ファイル.docx")

input_path = "#{input_base_path}/#{proc.folder}"
output_path = "#{output_base_path}/#{proc.folder}"

signed_xml_path = "#{input_path}/#{proc.kousei_xml}"
style_file_path = "#{input_path}/#{proc.application_xml}"
attachment_file_path = "#{input_path}/#{proc.attachment_file}"
app_files_path = ["#{style_file_path}", "#{attachment_file_path}"]

# Zipper生成
pkcs12 = OpenSSL::PKCS12.new(File.open(Key, "rb"),password)
zipper = Kiji::Zipper.new() do |s|
  s.cert = pkcs12.certificate
  s.private_key = pkcs12.key
end

# 署名を行う
signer = zipper.sign(signed_xml_path, app_files_path)

# 申請フォルダを作成する
FileUtils.mkdir_p(output_path)

# 署名付きxmlを書き出す
File.write("#{output_path}/#{proc.kousei_xml}", signer.to_xml)

# 申請書XML、添付ファイルをコピーする
app_files_path.each do |f|
  FileUtils.cp(f, output_path)
end

# 出力先にあるフォルダをzipに固める
zipper.write_zip(output_base_path, "#{output_base_path}/apply_data.zip")
