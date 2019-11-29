require "test_helper"

describe Supergroups::NewsAndCommunications do
  include RummagerHelpers
  include SupergroupHelpers

  DEFAULT_WHITEHALL_IMAGE_URL = "https://assets.publishing.service.gov.uk/government/assets/placeholder.jpg".freeze
  let(:taxon_id) { "12345" }
  let(:news_and_communications_supergroup) { Supergroups::NewsAndCommunications.new }

  describe "#document_list" do
    it "returns a document list for the news and communications supergroup" do
      MostRecentContent.any_instance
        .stubs(:fetch)
        .returns(section_tagged_content_list("news_story", 2))

      expected = [
        {
          link: {
            text: "Tagged Content Title",
            path: "/government/tagged/content",
            data_attributes: {
              module: "track-click",
              track_category: "newsAndCommunicationsDocumentListClicked",
              track_action: 1,
              track_label: "/government/tagged/content",
              track_options: {
                dimension29: "Tagged Content Title",
              },
            },
          },
          metadata: {
            public_updated_at: "2018-02-28T08:01:00.000+00:00",
            organisations: "Tagged Content Organisation",
            document_type: "News story",
          },
        },
      ]

      assert_equal expected, news_and_communications_supergroup.document_list(taxon_id)
    end

    it "does not returns an image for news items" do
      tagged_document_list = %w(news_story correspondance press_release)

      MostRecentContent.any_instance
        .stubs(:fetch)
        .returns(tagged_content(tagged_document_list))

      news_and_communications_supergroup.document_list(taxon_id).each do |content_item|
        assert_not content_item.key?(:image)
      end
    end
  end

  describe "#promoted_content" do
    before do
      content = content_item_for_base_path("/government/tagged/content").merge(
        "details": {
          "image": {
            "url": "an/image/path",
          },
        },
      )

      content_store_has_item("/government/tagged/content", content)
    end

    it "returns promoted content for the news and communications section" do
      MostRecentContent.any_instance
        .stubs(:fetch)
        .returns(section_tagged_content_list("news_story"))

      expected = [
        {
          link: {
            text: "Tagged Content Title",
            path: "/government/tagged/content",
            data_attributes: {
              module: "track-click",
              track_category: "newsAndCommunicationsFeaturedLinkClicked",
              track_action: 1,
              track_label: "/government/tagged/content",
              track_options: {
                dimension29: "Tagged Content Title",
              },
            },
          },
          metadata: {
            public_updated_at: "2018-02-28T08:01:00.000+00:00",
            organisations: "Tagged Content Organisation",
            document_type: "News story",
          },
          image: {
            url: "an/image/path",
          },
        },
      ]

      assert_equal expected, news_and_communications_supergroup.promoted_content(taxon_id)
    end

    it "returns an image for the first news item" do
      tagged_document_list = %w(news_story correspondance press_release)

      MostRecentContent.any_instance
        .stubs(:fetch)
        .returns(tagged_content(tagged_document_list))

      promoted_news = news_and_communications_supergroup.promoted_content(taxon_id)

      assert_equal 1, promoted_news.size
      assert promoted_news.first.key?(:image)
    end

    it "returns the default whitehall image if no image is present" do
      content_list = section_tagged_content_list("news_story")
      content_list.each { |content| content.image_url = nil }
      MostRecentContent.any_instance
      .stubs(:fetch)
      .returns(content_list)

      assert_equal DEFAULT_WHITEHALL_IMAGE_URL, news_and_communications_supergroup.promoted_content(taxon_id).first[:image][:url]
    end
  end

  describe "document types" do
    it "returns appropriate things" do
      document_types = GovukDocumentTypes.supergroup_document_types("news_and_communications")

      assert_includes document_types, "speech"
    end
  end
end
