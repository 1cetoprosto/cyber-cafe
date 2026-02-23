require 'xcodeproj'

project_path = '/Users/leonidkvit/Documents/Swift/Projekts/Freelance/cyber-coffe/TrackMyCafe.xcodeproj'
project = Xcodeproj::Project.open(project_path)

def add_file(project, file_path)
  # Remove the project root part if present to get relative path from project root
  relative_path = file_path.sub('/Users/leonidkvit/Documents/Swift/Projekts/Freelance/cyber-coffe/', '')
  
  group_names = File.dirname(relative_path).split('/')
  filename = File.basename(relative_path)
  
  # Navigate to the correct group
  current_group = project.main_group
  
  group_names.each do |name|
    # Try to find existing group
    found_group = current_group.children.find { |child| child.isa == 'PBXGroup' && child.name == name } || 
                  current_group.children.find { |child| child.isa == 'PBXGroup' && child.path == name }
    
    if found_group
      current_group = found_group
    else
      # If not found, create it (shouldn't happen for existing folders usually, but good fallback)
      # For this specific task, we expect the folders to exist
      puts "Warning: Group #{name} not found in #{current_group.display_name}. Creating it."
      current_group = current_group.new_group(name, name)
    end
  end
  
  # Check if file already exists
  if current_group.files.any? { |f| f.path == filename || f.name == filename }
    puts "File #{filename} already exists in group."
    return
  end
  
  # Create file reference
  # We use the filename because the group path should be set correctly
  file_ref = current_group.new_file(filename)
  
  # Add to all targets
  project.targets.each do |target|
    target.add_file_references([file_ref])
  end
  
  puts "Added #{filename} to #{current_group.display_name} and all targets."
end

files = [
  'TrackMyCafe/Data Layer/Models/Firestore/FIRInventoryAdjustmentModel.swift',
  'TrackMyCafe/Data Layer/Models/Firestore/FIROpexExpenseModel.swift',
  'TrackMyCafe/Services/Domain/Aggregation/DashboardPeriod.swift',
  'TrackMyCafe/Services/Domain/Aggregation/OpexAggregationService.swift',
  'TrackMyCafe/Services/Domain/Aggregation/IncomeAggregationService.swift',
  'TrackMyCafe/Services/Domain/Aggregation/FinanceAggregationService.swift'
]

files.each do |file|
  add_file(project, file)
end

project.save
