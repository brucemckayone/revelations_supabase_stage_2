import {
  startTest,
  endTest,
  logSection,
  logRequirement,
  logAction,
  logVerify,
  assert,
  assertEqual,
  assertNotNull,
} from "../../../shared/utilities/test-utils.js";
import { NotificationsFixtures } from "../fixtures.js";
import { supabase } from "../../../config/database.js";

export async function runNotificationTemplatesTests() {
  const fixtures = new NotificationsFixtures();

  try {
    await testEmailTemplateCreation(fixtures);
    await testNotificationTemplateCreation(fixtures);
    await testTemplateVariables(fixtures);
    await testTemplateActivation(fixtures);
    await testTemplateQuerying(fixtures);
  } finally {
    await fixtures.cleanup();
  }
}

async function testEmailTemplateCreation(fixtures) {
  startTest("Email Template Creation");

  logSection("Setup Email Template Environment");
  logRequirement("System must support customizable email templates");
  logRequirement("Templates must support variable replacement");

  logAction("Creating email template");
  const template = await fixtures.createTestEmailTemplate();

  logVerify("Email template created successfully");
  assertNotNull(template.id, "Template should have valid ID");
  assertNotNull(template.name, "Template should have unique name");
  assertNotNull(template.subject, "Template should have subject");
  assertNotNull(template.html_content, "Template should have HTML content");
  assertNotNull(template.text_content, "Template should have text content");
  assertEqual(template.is_active, true, "Template should be active by default");
  assertNotNull(template.variables, "Template should have variables list");

  endTest();
}

async function testNotificationTemplateCreation(fixtures) {
  startTest("Notification Template Creation");

  logSection("Setup Notification Template Environment");
  logRequirement("Users must be able to create reusable notification templates");
  logRequirement("Templates must be linked to creators");

  logAction("Creating notification template");
  const template = await fixtures.createTestNotificationTemplate();

  logVerify("Notification template created successfully");
  assertNotNull(template.id, "Template should have valid ID");
  assertNotNull(template.creator_id, "Template should be linked to creator");
  assertNotNull(template.title, "Template should have title");
  assertNotNull(template.content, "Template should have content");
  assertEqual(template.type, "system", "Template should have correct type");

  endTest();
}

async function testTemplateVariables(fixtures) {
  startTest("Template Variable Handling");

  logSection("Test Variable Replacement");
  logRequirement("Templates must support dynamic variable replacement");
  logRequirement("Variables must be clearly defined and documented");

  logAction("Creating template with variables");
  const template = await fixtures.createTestEmailTemplate({
    subject: "Hello {{user_name}} - {{event_title}}",
    html_content: `
      <html>
        <body>
          <h1>Hello {{user_name}}!</h1>
          <p>{{content}}</p>
          <p>Event: {{event_title}} on {{event_date}}</p>
          <a href="{{action_url}}">{{action_text}}</a>
        </body>
      </html>
    `,
    text_content: "Hello {{user_name}}!\n\n{{content}}\n\nEvent: {{event_title}} on {{event_date}}\n\nAction: {{action_url}}",
    variables: ["user_name", "content", "event_title", "event_date", "action_url", "action_text"]
  });

  logVerify("Template with variables created");
  assertEqual(template.variables.length, 6, "Should track all template variables");
  assert(template.variables.includes("user_name"), "Should include user_name variable");
  assert(template.variables.includes("event_title"), "Should include event_title variable");
  assert(template.html_content.includes("{{user_name}}"), "HTML should contain variable placeholders");
  assert(template.text_content.includes("{{content}}"), "Text should contain variable placeholders");

  endTest();
}

async function testTemplateActivation(fixtures) {
  startTest("Template Activation Management");

  logSection("Test Template Active Status");
  logRequirement("Templates must be activatable/deactivatable");
  logRequirement("Only active templates should be used for notifications");

  logAction("Creating active template");
  const activeTemplate = await fixtures.createTestEmailTemplate({
    is_active: true
  });

  logAction("Creating inactive template");
  const inactiveTemplate = await fixtures.createTestEmailTemplate({
    name: `TEST_InactiveTemplate_${Date.now()}`,
    is_active: false
  });

  logVerify("Templates created with different activation states");
  assertEqual(activeTemplate.is_active, true, "Active template should be marked as active");
  assertEqual(inactiveTemplate.is_active, false, "Inactive template should be marked as inactive");

  logAction("Testing active template queries");
  const { data: activeTemplates, error } = await supabase
    .from("email_templates")
    .select("*")
    .eq("is_active", true)
    .like("name", "TEST_%");

  assert(!error, "Should be able to query active templates");
  assert(activeTemplates.length >= 1, "Should find active test templates");
  assert(activeTemplates.some(t => t.id === activeTemplate.id), "Should include our active template");

  logAction("Testing template deactivation");
  const { data: deactivatedTemplate, error: deactivateError } = await supabase
    .from("email_templates")
    .update({ 
      is_active: false,
      updated_at: new Date().toISOString()
    })
    .eq("id", activeTemplate.id)
    .select()
    .single();

  assert(!deactivateError, "Should be able to deactivate template");
  assertEqual(deactivatedTemplate.is_active, false, "Template should be deactivated");

  endTest();
}

async function testTemplateQuerying(fixtures) {
  startTest("Template Querying and Retrieval");

  logSection("Test Template Lookup");
  logRequirement("System must efficiently find templates by name and type");
  logRequirement("Template queries must support filtering by activation status");

  // Create templates for different notification types
  const templateTypes = ["booking", "reminder", "cancellation", "waitlist"];
  const createdTemplates = {};

  for (const type of templateTypes) {
    logAction(`Creating ${type} template`);
    
    createdTemplates[type] = await fixtures.createTestEmailTemplate({
      name: `TEST_${type}_notification_${Date.now()}`,
      subject: `${type.charAt(0).toUpperCase() + type.slice(1)} - {{title}}`,
      html_content: `<h1>${type.charAt(0).toUpperCase() + type.slice(1)}</h1><p>{{content}}</p>`,
      variables: ["title", "content"]
    });
  }

  logAction("Testing template lookup by name");
  const bookingTemplateName = createdTemplates.booking.name;
  const { data: foundTemplate, error: lookupError } = await supabase
    .from("email_templates")
    .select("*")
    .eq("name", bookingTemplateName)
    .eq("is_active", true)
    .single();

  assert(!lookupError, "Should be able to find template by name");
  assertEqual(foundTemplate.name, bookingTemplateName, "Should find correct template");
  assertEqual(foundTemplate.is_active, true, "Found template should be active");

  logAction("Testing template filtering");
  const { data: testTemplates, error: filterError } = await supabase
    .from("email_templates")
    .select("*")
    .like("name", "TEST_%")
    .eq("is_active", true)
    .order("created_at", { ascending: false });

  assert(!filterError, "Should be able to filter templates");
  assert(testTemplates.length >= templateTypes.length, "Should find all test templates");

  logVerify("Template querying working correctly");

  endTest();
}


