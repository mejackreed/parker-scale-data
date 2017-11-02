require 'faraday'
require 'csv'
require 'iiif/presentation'
require 'securerandom'

manifest_base = 'https://dms-data.stanford.edu/data/manifests/Parker'
deploy_base = 'https://mejackreed.github.io/parker-scale-data'

CSV.foreach('./druids.csv') do |row|
  puts row.first.inspect
  druid = row.first
  Dir.mkdir(druid) unless Dir.exist?(druid)
  mani = IIIF::Service.parse(Faraday.get("#{manifest_base}/#{druid}/manifest.json").body)
  mani.sequences.each do |sequence|
    sequence.canvases.each_with_index do |canvas, i|
      anno_list_id = "#{deploy_base}/#{druid}/annos/canvas-#{i + 1}.json"
      oc = IIIF::Presentation::Resource.new(
        '@id' => anno_list_id,
        '@type' => 'sc:AnnotationList'
      )
      canvas.other_content = [oc]
      Dir.mkdir(File.join(druid, 'annos')) unless Dir.exist?(File.join(druid, 'annos'))
      anno_list = IIIF::Presentation::AnnotationList.new(
        '@context' => 'http://iiif.io/api/presentation/2/context.json',
        '@id' => anno_list_id
      )
      anno_list.resources = []
      anno_list.resources << IIIF::Presentation::Resource.new(
        '@id' => "#{SecureRandom.hex}",
        '@type' => 'oa:Annotation',
        'motivation' => 'sc:painting',
        'resource' => {
          '@id' => "#{SecureRandom.hex}",
          '@type' => 'cnt:ContentAsText',
          'format' => 'text/plain',
          'chars' => 'Hello!',
          'language' => 'eng'
        },
        'on' => "#{canvas['@id']}#xywh=0,0,300,300"
      )
      File.open(File.join(druid, 'annos', "canvas-#{i + 1}.json"), 'wb') do |f|
        f.write anno_list.to_json(pretty: true)
      end
    end
  end
  File.open("#{druid}/manifest.json", 'wb') do |f|
    f.write mani.to_json(pretty: true)
  end
end
