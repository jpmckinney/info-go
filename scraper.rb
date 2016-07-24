require 'rubygems'
require 'bundler/setup'

require 'fileutils'

require 'pupa'

class Processor < Pupa::Processor
  def path(directory, id)
    if directory == 'people'
      File.join('people', id.to_s[0, 2], "#{id}.json")
    elsif directory == 'organizations'
      File.join('organizations', "#{id}.json")
    else
      raise "unrecognized directory #{directory}"
    end
  end

  def write(directory, id, data)
    filename = path(directory, id)

    FileUtils.mkdir_p(File.dirname(filename))

    File.open(filename, 'w') do |f|
      f.write(data)
    end
  end

  def warn_unless_exists(directory, id, path)
    if id && !File.exist?(path(directory, id))
      warn("new person (#{id}) found in #{path}")
    end
  end

  def dump_person(id)
    url = "http://www.infogo.gov.on.ca/infogo/v1/individuals/get?assignmentId=#{id}"
    data = get(url)
    write('people', id, data)
    person = JSON.load(data)

    if person
      warn_unless_exists('organizations', person.dig('reportsTo', 'associatedOrg', 'orgId'), 'reportsTo.associatedOrg.orgId')

      person['otherPositionAssignments'].each do |position|
        warn_unless_exists('organizations', position['associatedOrg']['orgId'], 'otherPositionAssignments[].associatedOrg.orgId')
      end
    else
      error("empty response from #{url}")
    end
  end

  def dump_organization(id)
    url = "http://www.infogo.gov.on.ca/infogo/v1/organizations/get?orgId=#{id}"
    data = get(url)
    write('organizations', id, data)
    organization = JSON.load(data)

    organization['childOrgs'].each do |child|
      dump_organization(child['orgId'])
      warn_unless_exists('people', child['head']['assignmentId'], 'childOrgs[].head.assignmentId')
    end

    organization['positions'].each do |position|
      dump_person(position['assignmentId'])
    end

    organization['indirectOrgs'].each do |indirect|
      indirect['orgs'].each do |org|
        warn_unless_exists('organizations', org['orgId'], 'indirectOrgs[].orgs[].orgId')
        warn_unless_exists('organizations', org['topOrg']['orgId'], 'indirectOrgs[].orgs[].topOrg.orgId')
      end
    end
  end

  def scrape_organizations
    JSON.load(get('http://www.infogo.gov.on.ca/infogo/v1/organizations/categories'))['categories'].each do |category|
      category['organizations'].each do |organization|
        dump_organization(organization['id'])
      end
    end
  end
end

Processor.add_scraping_task(:organizations)

runner = Pupa::Runner.new(Processor)
runner.run(ARGV)
