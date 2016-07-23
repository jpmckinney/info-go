require 'rubygems'
require 'bundler/setup'

require 'pupa'

class Processor < Pupa::Processor
  def dump_person(id)
    data = get("http://www.infogo.gov.on.ca/infogo/v1/individuals/get?assignmentId=#{id}")

    File.open(File.join('people', "#{id}.json"), 'w') do |f|
      f.write(data)
    end

    # reportsTo
    # otherPositionAssignments
  end

  def dump_organization(id)
    data = get("http://www.infogo.gov.on.ca/infogo/v1/organizations/get?orgId=#{id}")

    File.open(File.join('organizations', "#{id}.json"), 'w') do |f|
      f.write(data)
    end

    organization = JSON.load(data)

    organization['childOrgs'].each do |child|
      dump_organization(child['orgId'])
    end

    organization['positions'].each do |position|
      dump_person(position['assignmentId'])
    end

    # childOrgs[].head.assignmentId
    # indirectOrgs[].orgs[].orgId
    # indirectOrgs[].orgs[].topOrg.orgId
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
