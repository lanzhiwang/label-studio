# Contribute to Label Studio
为 Label Studio 做出贡献

Thanks for taking the time to contribute! Contributions from people like you help make Label Studio an amazing tool to use. 
感谢您抽出时间做出贡献！ 像您这样的人的贡献使 Label Studio 成为一个令人惊叹的工具。

This document provides guidelines for contributing code and documentation to Label Studio. Following these guidelines makes it easier for the maintainers to respond to your pull requests and provide timely and helpful feedback to help you finalize your requested changes.
本文档提供了向 Label Studio 贡献代码和文档的指南。 遵循这些准则可以让维护人员更轻松地响应您的拉取请求，并提供及时且有用的反馈，以帮助您完成请求的更改。

## Types of Contributions
贡献类型

You can contribute to Label Studio by submitting [bug reports and feature requests](https://github.com/heartexlabs/label-studio/issues/new/choose), or by writing code to do any of the following:
您可以通过提交错误报告和功能请求，或编写代码来执行以下任一操作，为 Label Studio 做出贡献：

- Fix a bug.

- Provide [example machine learning backend code](https://github.com/heartexlabs/label-studio-ml-backend) to help others add a machine learning backend for a specific model.
  提供示例机器学习后端代码，以帮助其他人为特定模型添加机器学习后端。

- Share [example annotation templates](https://github.com/heartexlabs/label-studio/tree/master/label_studio/annotation_templates) for specific use cases.
  分享特定用例的示例注释模板。

- Add [new export formats](https://github.com/heartexlabs/label-studio-converter) for labeling projects.
  为标签项目添加新的导出格式。

- Support a new type of labeling or [extend existing labeling functionality](https://github.com/heartexlabs/label-studio-frontend). 
  支持新型标签或扩展现有标签功能。

We also welcome contributions to [the documentation](https://github.com/heartexlabs/label-studio/tree/master/docs/source)! 
我们也欢迎对文档做出贡献！

Please don't use the issue tracker to ask questions. Instead, join the [Label Studio Slack Community](https://slack.labelstudio.heartex.com/?source=github-contrib) to get help!
请不要使用问题跟踪器来提问。 相反，请加入 Label Studio Slack 社区来获取帮助！

If you're not sure whether an idea you have for Label Studio matches up with our planned direction, check out the [public roadmap](https://github.com/heartexlabs/label-studio/blob/master/roadmap.md) first. 
如果您不确定您对 Label Studio 的想法是否符合我们计划的方向，请先查看公共路线图。

## How to Start Contributing
如何开始贡献

If you want to contribute to Label Studio, but aren't sure where to start, review the [issues tagged with "good first issue"](https://github.com/heartexlabs/label-studio/labels/good%20first%20issue) or take a look at [the existing issues](https://github.com/heartexlabs/label-studio/issues) to see if any interest you.
如果您想为 Label Studio 做出贡献，但不确定从哪里开始，请查看标记为“好第一期”的问题或查看现有问题，看看是否有您感兴趣的问题。

If you decide to work on an issue, leave a comment so that you don't duplicate work that might be in progress and to coordinate work with others. 
如果您决定解决某个问题，请发表评论，以便您不会重复可能正在进行的工作并与其他人协调工作。

If you haven't opened a pull request before, check out the [GitHub documentation on pull requests](https://docs.github.com/en/github/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests).
如果您之前没有打开过拉取请求，请查看有关拉取请求的 GitHub 文档。

## Contributor Guidelines
贡献者指南

We value input from each member of the community, and we ask that you follow our [code of conduct](https://github.com/heartexlabs/label-studio/blob/master/CODE_OF_CONDUCT.md). We are a small team, but we try to respond to issues and pull requests within 2 business days. 
我们重视社区每个成员的意见，并要求您遵守我们的行为准则。 我们是一个小团队，但我们会尽力在 2 个工作日内响应问题并拉取请求。

### Before you start
在你开始之前

For changes that you contribute to any of the Label Studio repositories, please do the following:
对于您对任何 Label Studio 存储库做出的更改，请执行以下操作：

- Create issues for any major changes and enhancements that you want to make. 
  为您想要进行的任何重大更改和增强创建问题。

- Keep pull requests specific to one issue. Shorter pull requests are preferred and are easier to review. 
  保持拉取请求特定于一个问题。 较短的拉取请求是首选，并且更容易审查。

### Committing code
提交代码

Make sure that you contribute your changes to the correct repository. Label Studio is built in a few separate repositories including this one:
确保您将更改贡献到正确的存储库。 Label Studio 内置于几个独立的存储库中，包括这个：

- Changes to the data manager belong in the [data manager repository](https://github.com/heartexlabs/dm2).
  对数据管理器的更改属于数据管理器存储库。

- Changes to the labeling or editing workflow belong in the [label-studio-frontend repository](https://github.com/heartexlabs/label-studio-frontend).
  对标签或编辑工作流程的更改属于 label-studio-frontend 存储库。

- Changes to the export formats available in Label Studio belong in the [label studio converter repository](https://github.com/heartexlabs/label-studio-converter).
  对 Label Studio 中可用导出格式的更改属于 label studio 转换器存储库。

- Changes to the machine learning backend functionality belong in the [label-studio-ml-backend repository](https://github.com/heartexlabs/label-studio-ml-backend).
  对机器学习后端功能的更改属于 label-studio-ml-backend 存储库。

### Code standards
代码标准

Follow these code formatting guidelines:
请遵循以下代码格式指南：

- Lint your Python code with [black](https://github.com/psf/black) using `--skip-string-normalization`. 
  使用 --skip-string-normalization 将 Python 代码变成黑色。

- Use single quotes for strings.
  对字符串使用单引号。

- Use comments to describe code blocks. 
  使用注释来描述代码块。

- When possible, use the following conventions for your commit messages:
  如果可能，请对提交消息使用以下约定：

  - prefix with [fix] for bugfix changes
    前缀为 [fix] 的错误修复更改

  - prefix with [ext] for feature or external-facing changes
    前缀 [ext] 用于功能或面向外部的更改

  - prefix with [docs] for doc-only changes
    前缀为 [docs] 的仅用于文档更改

### Testing
- Make sure that changes you make work on Windows, Mac, and Linux operating systems.
  确保您所做的更改在 Windows、Mac 和 Linux 操作系统上有效。

- Include unit tests when you contribute bug fixes and new features. Unit tests help prove that your code works correctly and protects against future breaking changes.
  当您贡献错误修复和新功能时，请包括单元测试。 单元测试有助于证明您的代码正常工作并防止未来发生重大更改。

- Make sure that the code coverage checks and automatic tests for pull requests pass. 
  确保代码覆盖率检查和拉取请求的自动测试通过。

### Additional questions

If you have any questions that aren't answered in these guidelines, please find us in the #contributor channel of the [Label Studio Slack Community](https://slack.labelstudio.heartex.com/?source=github-contrib).
如果您有任何这些指南中未解答的问题，请在 Label Studio Slack 社区的 #contributor 频道中找到我们。
