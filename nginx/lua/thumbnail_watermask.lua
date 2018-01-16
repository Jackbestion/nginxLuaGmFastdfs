-- lua通过请求的url,执行图片压缩命令,生成新的图片,并重定向至新url

-- nginx解析最后一级形如: ezkqoVe7ss2AMwCcAAAlMBncGCs752_600x600q90generatorRongshuWatermask.jpg 的请求
-- if ($image_name ~ "([a-zA-Z0-9]+)_([0-9]+x[0-9]+)?(q[0-9]{1,2})?.([a-zA-Z0-9]+)") {
--     set $a  "$1"; --> fastdfs文件名称ID(不包含后缀),形如: zkqoVe7ss2AMwCcAAAlMBncGCs752
--     set $b  "$2"; --> 宽高转换参数,形如: 600x600
--     set $c  "$3"; --> 压缩质量,透明度具体数值,形如: q90
--     set $d  "$4"; --> 水印类型名称flag(用于添加不同类型的水印) 
--     set $e  "$5"; --> 图片文件后缀名,形如: jpg
-- }

local preName = ngx.var.a  -- fastdfs文件名称ID(不包含后缀),形如: wKi0E1g3r0OAXIsLAAHx975mHFw27 
local whParam = ngx.var.b  -- 宽高转换参数,形如: 200x200
local qParams = ngx.var.c  -- 压缩质量参数(非水印转换) || 透明度参数(添加水印)
local qParam = string.sub(qParams,2) -- 压缩质量,透明度具体数值
local watermask = ngx.var.d  -- 水印类型名称flag(用于添加不同类型的水印) 
local suffix = ngx.var.e  -- 图片文件后缀名
local image_dir = ngx.var.image_dir -- fastdfs文件存储路径,形如: /opt/fastdfs/storage/data/00/00/
local url_mid_path = ngx.var.url_mid_path  -- fastdfs二级目录路径,形如:  00/00
local watermaskXiaqiuIMG = "/opt/fastdfs/storage/data/00/00/wKi0E1fouCqAdb5vAAASg7eOgY4177.png" -- 虾球水印图片
local watermaskRongshuIMG = "/opt/fastdfs/storage/data/00/00/rongshu.jpg" -- 榕树水印图片
local originFileName = image_dir .. preName .. "." .. suffix -- 原始文件路径
local originFileUrl = ngx.var.img_urlroot_path .. url_mid_path .. "/" .. preName .. "." .. suffix -- 原始文件URL /group1/M00/xx/xx/xxx.jpg
local command = ""

function file_exists(path) -- 判断文件是否存在
  local file = io.open(path, "rb")
  if file then file:close() end
  return file ~= nil
end

os.execute("echo 环境变量: $PATH > /opt/nginx/conf/lua/lualog.txt")
os.execute("echo gm所在位置: type gm >> /opt/nginx/conf/lua/lualog.txt")
os.execute("echo 原始图片URL: " .. originFileUrl .. " >> /opt/nginx/conf/lua/lualog.txt")
os.execute("echo 原始文件路径: " .. originFileName .. " >> /opt/nginx/conf/lua/lualog.txt")
os.execute("echo 文件ID名称前缀: " .. preName .. " >> /opt/nginx/conf/lua/lualog.txt")
os.execute("echo 宽高转换参数: " .. whParam .. " >> /opt/nginx/conf/lua/lualog.txt")
os.execute("echo 质量|透明度参数: " .. qParam .. " >> /opt/nginx/conf/lua/lualog.txt")
os.execute("echo 水印类型: " .. watermask .. " >> /opt/nginx/conf/lua/lualog.txt")
os.execute("echo 原始文件路径: " .. originFileName .. " >> /opt/nginx/conf/lua/lualog.txt")
os.execute("echo fastdfs文件存储路径: " .. image_dir .. " >> /opt/nginx/conf/lua/lualog.txt")
os.execute("echo fastdfs二级目录路径: " .. url_mid_path .. " >> /opt/nginx/conf/lua/lualog.txt")

if (file_exists(originFileName))
then
    if (watermask=="generatorXiaqiuWatermask") -- 给虾球添加水印
    then
        command = "gm composite -gravity center "
        if (qParams=="")
            then
                command = command .. " -dissolve 70 "
            else
                command = command .. " -dissolve " .. qParam .. " "
        end
        command = command .. watermaskXiaqiuIMG .. " " .. originFileName .. " " .. originFileName
        os.execute("echo 覆盖生成虾球水印图片,GM执行命令: " .. command .. " >> /opt/nginx/conf/lua/lualog.txt")
        os.execute(command)
        -- os.execute("sleep " .. 1) -- 等待1秒,在执行nginx重定向
        ngx.redirect(originFileUrl)

    elseif (watermask=="generatorRongshuWatermask")  -- 给榕树添加水印
    then
        command = "gm composite -gravity center "
        if (qParams=="")
            then
                command = command .. " -dissolve 70 "
            else
                command = command .. " -dissolve " .. qParam .. " "
        end
        command = command .. watermaskRongshuIMG .. " " .. originFileName .. " " .. originFileName
        os.execute("echo 覆盖生成榕树水印图片,GM执行命令: " .. command .. " >> /opt/nginx/conf/lua/lualog.txt")
        os.execute(command)
        -- os.execute("sleep " .. 1) -- 等待1秒,在执行nginx重定向
        ngx.redirect(originFileUrl)
    else
        command = "gm convert " .. image_dir .. preName .. "." ..  suffix
        if (whParam=="")
            then
            else
                command = command .. " -thumbnail " .. whParam
        end
        if (qParams=="")
            then
            else
                command = command .. " -quality " .. qParam
        end
        command = command .. " " .. ngx.var.file
        os.execute("echo 执行图片压缩优化,GM执行命令: " .. command .. " >> /opt/nginx/conf/lua/lualog.txt")
        os.execute(command)

        -- 线上环境,生成新图片后,需要重定向至cdn源站,否则将会引起cdn无限制重定向到自身
        -- local targetUrl = ngx.var.scheme .. "://src.shuqucdn.com" .. ngx.var.uri
        -- local targetUrl = ngx.var.scheme .. "://toolsdev.shuqudata.com" .. ngx.var.uri
        -- os.execute("echo targetUrl=" .. targetUrl .. " > /opt/nginx/conf/lua/lualog.txt")
        -- ngx.redirect(targetUrl)

        -- 日常环境无需重定向到源站,只需要重定向到原始路径即可
        -- os.execute("sleep " .. 1) -- 等待1秒,在执行nginx重定向
        ngx.redirect(ngx.var.uri)
    end
else
    os.execute("echo 找不到图片文件: " .. originFileName .. " >> /opt/nginx/conf/lua/lualog.txt")
    ngx.redirect("/404")
end