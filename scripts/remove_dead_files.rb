#!/usr/bin/env ruby
# One-off hygiene script: unregister the Journal module + stray Hello-World
# stubs from the Xcode project. Safe — these files have zero references
# elsewhere and JournalEntry was never in the CoreData model.
require "xcodeproj"

STRAY_BASENAMES = %w[TestUIView.swift SotheaView.swift].freeze

proj = Xcodeproj::Project.open("SmartFarm.xcodeproj")

to_remove = proj.files.select do |f|
  path = (f.real_path.to_s rescue f.path.to_s)
  path.include?("/SmartFarm/Journal/") || STRAY_BASENAMES.include?(File.basename(path))
end

puts "Removing #{to_remove.size} file reference(s):"
to_remove.each do |f|
  puts "  - #{f.path}"
  f.build_files.dup.each(&:remove_from_project)
  f.remove_from_project
end

# Drop the now-empty Journal group tree.
journal_group = proj.main_group.find_subpath("SmartFarm/Journal")
if journal_group
  journal_group.recursive_children.each(&:remove_from_project)
  journal_group.remove_from_project
  puts "Removed SmartFarm/Journal group tree"
end

proj.save
puts "Saved project.pbxproj"
