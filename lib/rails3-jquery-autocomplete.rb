require 'form_helper'

module Rails3JQueryAutocomplete
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Inspired on DHH's autocomplete plugin
  #
  # Usage:
  #
  # class ProductsController < Admin::BaseController
  #   autocomplete :brand, :name
  # end
  #
  # This will magically generate an action autocomplete_brand_name, so,
  # don't forget to add it on your routes file
  #
  #   resources :products do
  #      get :autocomplete_brand_name, :on => :collection
  #   end
  #
  # Now, on your view, all you have to do is have a text field like:
  #
  #   f.text_field :brand_name, :autocomplete => autocomplete_brand_name_products_path
  #
  #
  module ClassMethods
    def autocomplete(object, method, options = {})
      isMongoId = object.to_s.camelize.constantize.included_modules.collect(&:to_s).include?("Mongoid::Document")
      limit = options[:limit] || 10
      order = options[:order]
      order = isMongoId ? method.to_sym.asc : "#{method} ASC"

      define_method("autocomplete_#{object}_#{method}") do
        unless params[:term] && params[:term].empty?
          if isMongoId
            search = (options[:full] ? '.*' : '^') + params[:term] + '.*'
            items = object.to_s.camelize.constantize.where(method.to_sym => /#{search}/i).limit(limit).order_by(method.to_sym.asc)
          else
            items = object.to_s.camelize.constantize.where(["LOWER(#{method}) LIKE ?", "#{(options[:full] ? '%' : '')}#{params[:term].downcase}%"]).limit(limit).order(order)
          end
        else
          items = {}
        end

        render :json => json_for_autocomplete(items, (options[:display_value] ? options[:display_value] : method))
      end
    end
  end

  private
  def json_for_autocomplete(items, method)
    items.collect {|i| {"id" => i.id, "label" => i.send(method), "value" => i.send(method)}}
  end
end

class ActionController::Base
  include Rails3JQueryAutocomplete
end
