# frozen_string_literal: true

# Reusable Tailwind class strings for forms and UI (keeps ERB under erb_lint line length).
module FormClassHelper
  def form_input_class
    "mt-1 block w-full rounded-md border border-slate-300 " \
      "dark:border-slate-600 dark:bg-slate-700 dark:text-slate-100 " \
      "px-3 py-2 shadow-sm focus:border-brand-500 focus:ring-brand-500 sm:text-sm"
  end

  def form_input_lg_class
    "mt-1 block w-full rounded-lg border border-slate-300 px-3 py-2 " \
      "text-sm shadow-sm focus:border-brand-500 focus:outline-none " \
      "focus:ring-1 focus:ring-brand-500 dark:border-slate-600 " \
      "dark:bg-slate-700 dark:text-slate-100"
  end

  def form_cancel_link_class
    "rounded-md border border-slate-300 dark:border-slate-600 px-4 py-2 text-sm " \
      "hover:bg-slate-100 dark:hover:bg-slate-700"
  end

  def form_input_shadow_class
    "mt-1 block w-full rounded-md border border-slate-300 px-3 py-2 " \
      "text-sm shadow-sm focus:border-brand-500 focus:ring-brand-500 " \
      "dark:border-slate-600 dark:bg-slate-700 dark:text-slate-100"
  end

  def form_file_input_class
    "mt-1 block w-full text-sm text-slate-500 dark:text-slate-400 " \
      "file:mr-4 file:rounded-md file:border-0 file:bg-brand-50 " \
      "file:px-3 file:py-2 file:text-sm file:font-medium file:text-brand-700 " \
      "hover:file:bg-brand-100 dark:file:bg-brand-900/40 dark:file:text-brand-400 " \
      "dark:hover:file:bg-brand-900/60"
  end

  def mobile_sign_out_button_class
    "mt-1 w-full cursor-pointer rounded-md border-0 bg-transparent px-2 py-2 " \
      "text-left text-sm text-[var(--color-text-secondary)] " \
      "hover:bg-[var(--color-surface-hover)]"
  end

  def theme_appearance_mode_button_class
    "inline-flex cursor-pointer items-center gap-2 rounded-lg border " \
      "border-slate-300 px-4 py-2.5 text-sm font-medium text-slate-700 " \
      "transition-colors hover:bg-slate-100 " \
      "focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 " \
      "focus-visible:ring-offset-2 " \
      "aria-pressed:border-brand-600 aria-pressed:bg-brand-600 aria-pressed:text-white " \
      "dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-700 " \
      "dark:aria-pressed:border-brand-600 dark:aria-pressed:bg-brand-600 " \
      "dark:aria-pressed:text-white"
  end

  def devise_form_submit_class
    "rounded-lg bg-brand-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm " \
      "hover:bg-brand-700 focus:outline-none focus:ring-2 " \
      "focus:ring-brand-500 focus:ring-offset-2 cursor-pointer"
  end

  def devise_wfull_submit_class
    "w-full rounded-lg bg-brand-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm " \
      "hover:bg-brand-700 focus:outline-none focus:ring-2 " \
      "focus:ring-brand-500 focus:ring-offset-2 cursor-pointer"
  end

  def panel_card_class
    "rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-slate-800"
  end

  def content_card_class
    "rounded-lg border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-slate-800"
  end

  def grid_card_class
    "rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition-colors " \
      "hover:border-brand-300 dark:border-slate-700 dark:bg-slate-800 dark:hover:border-brand-700"
  end

  def table_wrapper_class
    "overflow-hidden rounded-lg border border-slate-200 dark:border-slate-700"
  end

  def table_class
    "min-w-full divide-y divide-slate-200 text-sm dark:divide-slate-700"
  end

  def dashboard_list_link_class
    "block rounded-lg border border-slate-100 bg-slate-50/60 px-3 py-2 " \
      "text-sm transition hover:border-brand-200 hover:bg-white " \
      "dark:border-slate-700 dark:bg-slate-700/40 dark:hover:border-brand-700 " \
      "dark:hover:bg-slate-700"
  end
end
