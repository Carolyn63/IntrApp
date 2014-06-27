require 'rubygems'
require 'json'
require 'net/http'
require 'pp'

module Services
  module DigidataApi
    class Hash
      # the Properties Aspect - see /doc/MediaType.ashx#PropertiesAspect
      def properties
        return self['properties']
      end

      # the Associations Aspect - see /doc/MediaType.ashx#AssociationsAspect
      def associations
        return self['associations']
      end

      # the Neighbors Aspect - see /doc/MediaType.ashx#NeighborsAspect
      def neighbors
        return self['neighbors']
      end

      # the Collections Aspect - see /doc/MediaType.ashx#CollectionsAspect
      def collections
        return self['collections']
      end

      # the Members Aspect - see /doc/MediaType.ashx#MembersAspect
      def members
        return self['members']
      end

      # handy extension method that finds a member by comparing a
      # particular property of each member to the desired value
      def find_member_by_property(property_name, value)
        return self.members.select { |k| k.properties[property_name] == value }[0]
      end

      # this is a handy extension method that finds a DDRS link
      # by querying a document's Associations Aspect for links
      # with a rel attribute equal to the 'rel' parameter
      def find_link_by_relation(rel)
        links = self.associations['links'] # links to other resources
        return links.select { |k| k['rel'] == rel }[0]
      end

    end
  end
end
