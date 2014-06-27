module SupportHelper

  module Reasons
    LIST = [
      ["Please select...", ""],
      ["General Question", "General Question"],
      ["Feature Request", "Feature Request"],
      ["Bug", "Bug"],
      ["New Feature Question", "New Feature Question"],
      ["Application Question", "Application Question"]
    ]
  end

  def reason_list
    Reasons::LIST
  end

end
