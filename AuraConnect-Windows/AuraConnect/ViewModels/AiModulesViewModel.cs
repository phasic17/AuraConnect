using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using AuraConnect.Models;

namespace AuraConnect.ViewModels;

public partial class AiModulesViewModel : ObservableObject
{
    public ObservableCollection<AuraAIModule> Modules { get; } =
    [
        new("Medicine \u2022 Clinical Assistant",
            "Differential support, patient-friendly explanations, and guideline-aware reasoning (offline-ready).",
            "\uE8EA", "POPULAR"),   // Health icon
        new("Languages \u2022 Interpreter Pack",
            "High-accuracy translation, tone control, and multilingual tutoring for travel + business.",
            "\uE8C1", "NEW"),       // Chat icon
        new("Rocket Science \u2022 Propulsion & GNC",
            "Orbital basics, guidance/navigation/control concepts, and engineering-style problem breakdowns.",
            "\uE709", null),        // Map pin
        new("Law \u2022 Contract Reviewer",
            "Clause spotting, risk summaries, and plain-English explanations for common agreements.",
            "\uE8A5", "PRO"),       // Document icon
        new("Finance \u2022 Markets & Accounting",
            "Financial statement literacy, valuation frameworks, and market concept Q&A (not investment advice).",
            "\uE9D2", null),        // Line chart
        new("Software \u2022 Systems Engineer",
            "Architecture reviews, debugging checklists, code explanations, and best-practice patterns.",
            "\uE756", "POPULAR"),   // Developer tools
        new("Cybersecurity \u2022 Blue Team",
            "Threat modeling, detection playbooks, and incident-response guidance for defensive operations.",
            "\uE83D", null),        // Shield
        new("Education \u2022 Tutor Mode",
            "Step-by-step teaching, quizzes, and mastery paths tailored to your pace and learning style.",
            "\uE7BE", null),        // Education
        new("Psychology \u2022 Coaching Companion",
            "Goal setting, reflection prompts, and communication coaching with gentle tone control.",
            "\uEB52", "BETA"),      // Heart
        new("Creative \u2022 Story & Script Studio",
            "Worldbuilding, dialogue, outlines, and fast iteration with consistent voice and style.",
            "\uE734", null),        // Sparkle/Favorite
    ];
}
