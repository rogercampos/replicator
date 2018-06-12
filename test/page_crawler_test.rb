require_relative 'test_helper'

require_relative '../lib/page_crawler'



class PageCrawlerTest < Minitest::Test
  def test_a
    urls = Parser.new("https://supercalorias.com/", File.read("test/example_page.html"), "https").urls(host: "supercalorias.com")

    result = %w(
https://supercalorias.com/
https://supercalorias.com/empieza-aqui
https://supercalorias.com/mi-historia
https://supercalorias.com/preguntas-frequenes
https://supercalorias.com/guia-saludable-de-sustitucion-de-ingredientes
https://supercalorias.com/el-azucar-dulce-sabor-amargas-consequencias
https://supercalorias.com/las-proteinas
https://supercalorias.com/grasas-saludables-el-fin-de-la-guerra-contra-la-grasa
https://supercalorias.com/los-carbohidratos
https://supercalorias.com/vegetales-y-frutas
https://supercalorias.com/aquafaba-el-agua-magica-de-los-garbanzos
https://supercalorias.com/chocolate-blanco-vegano-sin-azucar
https://supercalorias.com/los-lacteos-alimentos-a-incluir-o-a-eliminar
https://supercalorias.com/ver-mas-contenido
https://supercalorias.com/porque-no-sirven-las-dietas-ebook-gratis
https://supercalorias.com/contacta
https://supercalorias.com/declaracion-de-intenciones
https://supercalorias.com/aviso-legal
https://supercalorias.com/politica-privacidad
https://supercalorias.com/darse-de-baja
https://supercalorias.com/assets/logo_small-cfcf19383d1797aa4cca614504fd1d793685128fee8f724e1af41d53241e49aa.png
https://supercalorias.com/system/uploads/post/11/main_image/lump-sugar-549096_1920-a81799dd431879abeccff5a3d83fc9c2.jpg
https://supercalorias.com/system/uploads/post/20/main_image/kaboompics_Crayfish%20on%20a%20blue%20plate-0587e73adc1e8dd5d4ef13b5af067fc6.jpg
https://supercalorias.com/system/uploads/post/3/main_image/Grasas%20saludables-233025a43210555b5e07a2b635c90474.jpg
https://supercalorias.com/system/uploads/post/18/main_image/jade-wulfraat-96023%20(1)-ba6e7943b6536c7eaccd6347e6c78f34.jpg
https://supercalorias.com/system/uploads/post/22/main_image/kaboompics_Jaki%20tytul-%20(2)-6b6454ab7781e02c9e5997c93303527f.jpg
https://supercalorias.com/system/uploads/post/116/main_image/aquafaba%20vs%20claras%20de%20huevo-a0a66d8ee7ac079844157333d549b9e4.jpg
https://supercalorias.com/system/uploads/post/124/main_image/snapseed-582aad59eb578d0f9f910b0c6b71c06c.jpg
https://supercalorias.com/system/uploads/post/16/main_image/glass-1587258_1920-4565c43b6d084a3e8ab693a3818bac8d.jpg
https://supercalorias.com/assets/ebook-5bdd237c3d5cf7b81ca017ee256e39e6ed8ca3eb3e3f348da46384bd0b265d89.jpg
https://supercalorias.com/system/uploads/post/3/main_image/Grasas%20saludables.jpg
https://supercalorias.com/apple-touch-icon-57x57.png
https://supercalorias.com/apple-touch-icon-114x114.png
https://supercalorias.com/apple-touch-icon-72x72.png
https://supercalorias.com/apple-touch-icon-144x144.png
https://supercalorias.com/apple-touch-icon-60x60.png
https://supercalorias.com/apple-touch-icon-120x120.png
https://supercalorias.com/apple-touch-icon-76x76.png
https://supercalorias.com/apple-touch-icon-152x152.png
https://supercalorias.com/favicon-196x196.png
https://supercalorias.com/favicon-96x96.png
https://supercalorias.com/favicon-32x32.png
https://supercalorias.com/favicon-16x16.png
https://supercalorias.com/favicon-128.png
https://supercalorias.com/assets/application-5366669c76a9cfb6c20a662650b28b24296d3482365c9c6acdda03b032d76642.css
https://supercalorias.com/assets/application-2a7b480f2c4f417be89d4a4566ccd53b8e6165191436412eb81eea9c55ffbf84.js
https://supercalorias.com/system/uploads/post/121/header_image/ornella-binni-224982-2f4c454aaef7db57beba902635785085.jpg
https://supercalorias.com/www.supercalorias.com/system/uploads/post/3/main_image/foo.jpg
https://supercalorias.com/list_log.php?m_id=7&l_id=43328
https://supercalorias.com/list_log.php?m_id=7&l_id=111
    )

    assert_equal result.size, urls.size

    result.each do |x|
      assert_includes urls, x
    end


    def sanitize_str(value)
      begin
        value.gsub(/[^[:print:]]/, '')
      rescue ArgumentError => e
        if e.message == "invalid byte sequence in UTF-8"
          value.encode(Encoding.find('UTF-8'), invalid: :replace, undef: :replace, replace: '')
        else
          raise
        end
      end
    end

    # a = "https://supercalorias.com/list_log.php?m_id=7&l_id=43328"
    # uri = Addressable::URI.parse(Addressable::URI.escape(a))
    #
    # a = "https://deathlogs.com/list_log.php?m_id=7"
    # html = sanitize_str sanitize_str(Downloader.new(url).get)
    #
    # urls = Parser.new(a, html, "https").urls(host: "deathlogs.com")
    #
    # urls.each do |x|
    #   p x
    # end

    #
    # a = "/about.php?m_id=7"
    # uri = Addressable::URI.parse(Addressable::URI.escape(a))
    # p uri.host
    # uri.host = "deathlogs.com"
    # uri.scheme = "https"
    #
    # p uri.to_s
  end
end