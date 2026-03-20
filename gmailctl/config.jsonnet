// Auto-imported filters by 'gmailctl download'.
//
// WARNING: This functionality is experimental. Before making any
// changes, check that no diff is detected with the remote filters by
// using the 'diff' command.

// Uncomment if you want to use the standard library.
// local lib = import 'gmailctl.libsonnet';
{
  version: "v1alpha3",
  author: {
    name: "Shaun McQuaker",
    email: "shaun.mcquaker@shopify.com"
  },
  // Note: labels management is optional. If you prefer to use the
  // GMail interface to add and remove labels, you can safely remove
  // this section of the config.
  labels: [
    {
      name: "Notes",
      color: {
        background: "#fbe983",
        text: "#594c05"
      }
    },
    {
      name: "Recruiting",
      color: {
        background: "#b99aff",
        text: "#ffffff"
      }
    },
    {
      name: "Leadership",
      color: {
        background: "#ff7537",
        text: "#ffffff"
      }
    },
    {
      name: "1 – Daily Emails/Plus Deep Dive"
    },
    {
      name: "1 – Daily Emails/Performance by Device"
    },
    {
      name: "1 – Daily Emails/Health Dashboard"
    },
    {
      name: "1 – Daily Emails/Pixels by Product"
    },
    {
      name: "1 – Daily Emails/Starter Plan"
    },
    {
      name: "1 – Daily Emails/Google Shopping Retail Ads"
    },
    {
      name: "2 – Weekly Emails",
      color: {
        background: "#16a765",
        text: "#ffffff"
      }
    },
    {
      name: "2 – Weekly Emails/Replatformers"
    },
    {
      name: "1 – Daily Emails/WAS 2023"
    },
    {
      name: "1 – Daily Emails/Googlebot 5xx errors"
    },
    {
      name: "1 – Daily Emails/SEO Radar"
    },
    {
      name: "1 – Daily Emails/Should Win Keywords"
    },
    {
      name: "1 – Daily Emails/Visualping"
    },
    {
      name: "1 – Daily Emails/SEO Deep Dive"
    },
    {
      name: "2 – Weekly Emails/Competitor Adds"
    },
    {
      name: "1 – Daily Emails/Monthly Cohort Metrics"
    },
    {
      name: "Growth Ideas",
      color: {
        background: "#fb4c2f",
        text: "#ffffff"
      }
    },
    {
      name: "1 – Daily Emails",
      color: {
        background: "#42d692",
        text: "#094228"
      }
    },
    {
      name: "Funnies",
      color: {
        background: "#2da2bb",
        text: "#ffffff"
      }
    },
    {
      name: "1 – Daily Emails/Must Win Keywords"
    },
    {
      name: "1 – Daily Emails/Replatformer Metrics"
    },
    {
      name: "1 – Daily Emails/Growth Executive Grid"
    },
    {
      name: "GitHub"
    },
    {
      name: "GCP Notices"
    },
    {
      name: "1 – Daily Emails/SERP Analyzer"
    },
    {
      name: "1 – Daily Emails/Merchant Link Monitoring"
    }
  ],
  rules: [
    // Google Cloud platform notices — infra team's problem, not ours.
    // Direct from GCP:
    {
      filter: {
        from: "CloudPlatform-noreply@google.com",
      },
      actions: {
        archive: true,
        markRead: true,
        labels: ["GCP Notices"],
      },
    },
    // GCP notices forwarded through mailing lists:
    {
      filter: {
        and: [
          { has: "Google Cloud" },
          { has: "mandatory service announcement" },
        ],
      },
      actions: {
        archive: true,
        markRead: true,
        labels: ["GCP Notices"],
      },
    },
    // Google Ads account admin notifications — user added/invited/removed, never actionable.
    {
      filter: {
        from: "ads-account-noreply@google.com",
      },
      actions: {
        archive: true,
        markRead: true,
      },
    },
    // GitHub notifications — archive unless Shaun was directly mentioned or authored the thread.
    {
      filter: {
        and: [
          { from: "notifications@github.com" },
          { not: { has: "because you were mentioned" } },
          { not: { has: "because you authored" } },
        ],
      },
      actions: {
        archive: true,
        markRead: true,
        labels: ["GitHub"],
      },
    },
    // Calendar noise — accepted invitations and canceled events.
    {
      filter: {
        and: [
          {
            to: "shaun.mcquaker@shopify.com"
          },
          {
            subject: "Accepted"
          },
          {
            query: "has accepted this invitation -{tentatively}"
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true
      }
    },
    {
      filter: {
        subject: "Canceled event:",
      },
      actions: {
        archive: true,
        markRead: true
      }
    },
    // Meeting notes (Gemini, etc.) — already in calendar, don't need inbox copy.
    {
      filter: {
        from: "gemini-notes@google.com",
      },
      actions: {
        archive: true,
        markRead: true,
      },
    },
    // Invoices — archive unless Shaun is named (those are his responsibility).
    {
      filter: {
        and: [
          { subject: "invoice" },
          { not: { has: "Shaun McQuaker" } },
          { not: { has: "shaun.mcquaker" } },
        ],
      },
      actions: {
        archive: true,
        markRead: true,
      },
    },
    // Google Search Console — merchant store noise, not actionable.
    {
      filter: {
        from: "sc-noreply@google.com",
      },
      actions: {
        archive: true,
        markRead: true
      }
    },
    {
      filter: {
        and: [
          {
            from: "growth-executive-grid@shopify.com"
          },
          {
            query: "list:(\u003cgrowth-executive-grid.shopify.com\u003e)"
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        category: "updates",
        labels: [
          "1 – Daily Emails/Growth Executive Grid"
        ]
      }
    },
    {
      filter: {
        from: "no-reply@dtdg.co"
      },
      actions: {
        archive: true,
        markRead: true
      }
    },
    {
      filter: {
        from: "alerts@seoradar.com"
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        category: "updates",
        labels: [
          "1 – Daily Emails/SEO Radar"
        ]
      }
    },
    {
      filter: {
        and: [
          {
            from: "growth-labs-starter-plan@shopify.com"
          },
          {
            query: "list:(\u003cgrowth-labs-starter-plan.shopify.com\u003e)"
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        category: "updates",
        labels: [
          "1 – Daily Emails/Starter Plan"
        ]
      }
    },
    {
      filter: {
        and: [
          {
            from: "growth-performance-by-device-type@shopify.com"
          },
          {
            query: "list:(\u003cgrowth-performance-by-device-type.shopify.com\u003e)"
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        category: "updates",
        labels: [
          "1 – Daily Emails/Performance by Device"
        ]
      }
    },
    {
      filter: {
        and: [
          {
            from: "growth-labs-seo-tools-should-win@shopify.com"
          },
          {
            query: "list:(\u003cgrowth-labs-seo-tools-should-win.shopify.com\u003e)"
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        category: "updates",
        labels: [
          "1 – Daily Emails/Should Win Keywords"
        ]
      }
    },
    {
      filter: {
        and: [
          {
            from: "growth-labs-seo-must-win@shopify.com"
          },
          {
            query: "list:(\u003cgrowth-labs-seo-must-win.shopify.com\u003e)"
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        category: "updates",
        labels: [
          "1 – Daily Emails/Must Win Keywords"
        ]
      }
    },
    {
      filter: {
        and: [
          {
            from: "growth-labs-monthly-cohort@shopify.com"
          },
          {
            query: "list:(\u003cgrowth-labs-monthly-cohort.shopify.com\u003e)"
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        category: "updates",
        labels: [
          "1 – Daily Emails/Monthly Cohort Metrics"
        ]
      }
    },
    {
      filter: {
        and: [
          {
            from: "Visualping"
          },
          {
            subject: "Difference detected on",
            isEscaped: true
          },
          {
            query: "list:(\u003cgrowth-labs.shopify.com\u003e)"
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        category: "updates",
        labels: [
          "1 – Daily Emails/Visualping"
        ]
      }
    },
    {
      filter: {
        and: [
          {
            from: "support@bugsnag.com"
          },
          {
            subject: "Your events are being dropped due to",
            isEscaped: true
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true,
        category: "updates"
      }
    },
    {
      filter: {
        and: [
          {
            from: "Growth Labs",
            isEscaped: true
          },
          {
            to: "growth-labs@shopify.com"
          },
          {
            subject: "Plus Deep Dive",
            isEscaped: true
          },
          {
            query: "list:(\u003cgrowth-labs.shopify.com\u003e)"
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        category: "updates",
        labels: [
          "1 – Daily Emails/Plus Deep Dive"
        ]
      }
    },
    {
      filter: {
        and: [
          {
            from: "growth-seo-grid@shopify.com"
          },
          {
            query: "list:(\u003cgrowth-seo-grid.shopify.com\u003e)"
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        category: "updates",
        labels: [
          "1 – Daily Emails/SEO Deep Dive"
        ]
      }
    },
    {
      filter: {
        and: [
          {
            from: "growth-labs-2023-report@shopify.com"
          },
          {
            subject: "WAS 2023",
            isEscaped: true
          },
          {
            query: "list:(\u003cgrowth-labs.shopify.com\u003e)"
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        category: "updates",
        labels: [
          "1 – Daily Emails/WAS 2023"
        ]
      }
    },
    {
      filter: {
        and: [
          {
            from: "growth-labs-replatformers@shopify.com"
          },
          {
            to: "growth-labs-replatformers@shopify.com"
          },
          {
            subject: "Replatformer Metrics",
            isEscaped: true
          },
          {
            query: "list:(\u003cgrowth-labs-replatformers.shopify.com\u003e)"
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        labels: [
          "1 – Daily Emails/Replatformer Metrics"
        ]
      }
    },
    {
      filter: {
        and: [
          {
            from: "growth-labs-googlebot-errors@shopify.com"
          },
          {
            to: "growth-labs-googlebot-errors@shopify.com"
          },
          {
            subject: "Googlebot 5xx errors",
            isEscaped: true
          },
          {
            query: "list:(\u003cgrowth-labs-team.shopify.com\u003e)"
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        labels: [
          "1 – Daily Emails/Googlebot 5xx errors"
        ]
      }
    },
    {
      filter: {
        and: [
          {
            from: "growth-labs-pixelgeddon@shopify.com"
          },
          {
            to: "growth-labs-pixelgeddon@shopify.com"
          },
          {
            subject: "Pixels by Product",
            isEscaped: true
          },
          {
            query: "list:(\u003cgrowth-labs.shopify.com\u003e)"
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        labels: [
          "1 – Daily Emails/Pixels by Product"
        ]
      }
    },
    // Looker Studio scheduled reports — direct + via mailing list.
    {
      filter: {
        subject: "Growth Labs Health Dashboard",
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        labels: [
          "1 – Daily Emails/Health Dashboard"
        ]
      }
    },
    {
      filter: {
        subject: "SEO SERP Analyzer",
      },
      actions: {
        archive: true,
        markRead: true,
        labels: [
          "1 – Daily Emails/SERP Analyzer"
        ]
      }
    },
    {
      filter: {
        subject: "Merchant Link Monitoring",
      },
      actions: {
        archive: true,
        markRead: true,
        labels: [
          "1 – Daily Emails/Merchant Link Monitoring"
        ]
      }
    },
    {
      filter: {
        and: [
          {
            from: "growth-labs-google-shopping-ads@shopify.com"
          },
          {
            to: "growth-labs-google-shopping-ads@shopify.com"
          },
          {
            subject: "Google Shopping Retail Ads",
            isEscaped: true
          },
          {
            query: "list:(\u003cgrowth-labs.shopify.com\u003e)"
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        labels: [
          "1 – Daily Emails/Google Shopping Retail Ads"
        ]
      }
    },
    {
      filter: {
        and: [
          {
            from: "growth-labs-replatformers@shopify.com"
          },
          {
            to: "growth-labs-replatformers@shopify.com"
          },
          {
            subject: "Replatformers"
          },
          {
            query: "list:(\u003cgrowth-labs.shopify.com\u003e) \"Weekly Replatformers\""
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        labels: [
          "2 – Weekly Emails/Replatformers"
        ]
      }
    },
    {
      filter: {
        and: [
          {
            from: "growth-labs-platform-adds@shopify.com"
          },
          {
            to: "growth-labs-platform-adds@shopify.com"
          },
          {
            subject: "Competitor weekly adds",
            isEscaped: true
          },
          {
            query: "list:(\u003cgrowth-labs-platform-adds.shopify.com\u003e)"
          }
        ]
      },
      actions: {
        archive: true,
        markRead: true,
        markSpam: false,
        labels: [
          "2 – Weekly Emails/Competitor Adds"
        ]
      }
    }
  ]
}
