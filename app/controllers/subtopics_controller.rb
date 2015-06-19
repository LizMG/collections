class SubtopicsController < ApplicationController
  before_filter { validate_slug_param(:topic_slug) }
  before_filter { validate_slug_param(:subtopic_slug) }
  before_filter :set_slimmer_format

  rescue_from GdsApi::HTTPNotFound, :with => :error_404

  def show
    @subtopic = Subtopic.find("/#{slug}")

    if @subtopic.parent
      set_slimmer_dummy_artefact(
        section_name: @subtopic.parent.title,
        section_link: @subtopic.parent.base_path
      )
    end
  end

  def latest_changes
    @subtopic = Subtopic.find("/#{slug}")

    slimmer_artefact = {
      section_name: @subtopic.title,
      section_link: @subtopic.base_path,
    }
    if @subtopic.parent
      slimmer_artefact[:parent] = {
        section_name: @subtopic.parent.title,
        section_link: @subtopic.parent.base_path,
      }
    end
    set_slimmer_dummy_artefact(slimmer_artefact)
  end

private

  def subtopic
    @subtopic ||= Subtopic.find(slug, pagination_params)
  end
  helper_method :subtopic

  def organisations
    @organisations ||= subtopic_organisations(slug)
  end
  helper_method :organisations

  def changed_documents_pagination
    @changed_documents_pagination ||= ChangedDocumentsPaginationPresenter.new(
      subtopic,
      per_page: pagination_params[:count]
    )
  end
  helper_method :changed_documents_pagination

  def send_404_if_not_found
    error_404 unless subtopic.present?
  end

  def set_slimmer_format
    set_slimmer_headers(format: "specialist-sector")
  end

  def slug
    "#{params[:topic_slug]}/#{params[:subtopic_slug]}"
  end

  def subtopic_organisations(slug)
    OrganisationsFacetPresenter.new(
      Collections::Application.config.search_client.unified_search(
        count: "0",
        filter_specialist_sectors: [slug],
        facet_organisations: "1000",
      )["facets"]["organisations"]
    )
  end

  def pagination_params
    params_to_use = params.slice(:start, :count).symbolize_keys

    # primitive sanitisation of the pagination parameters to ensure they're
    # integers
    params_to_use.inject({}) {|hash, (key, value)|
      hash[key] = value.to_i if value.present?
      hash
    }
  end
end
