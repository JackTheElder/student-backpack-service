FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
WORKDIR /app
EXPOSE 80

ENV ASPNETCORE_URLS=http://+:80
ENV ASPNETCORE_ENVIRONMENT=Development

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
ARG configuration=Release

ARG FEED_ACCESS_USERNAME="Docker"
ARG FEED_ACCESS_TOKEN
ENV DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0
ENV NUGET_CREDENTIALPROVIDER_SESSIONTOKENCACHE_ENABLED true
ENV VSS_NUGET_EXTERNAL_FEED_ENDPOINTS {\"endpointCredentials\": [{\"endpoint\":\"https://pkgs.dev.azure.com/UtahPublicEd/_packaging/Platform/nuget/v3/index.json\", \"username\":\"${FEED_ACCESS_USERNAME}\", \"password\":\"${FEED_ACCESS_TOKEN}\"}]}
RUN wget -qO- https://aka.ms/install-artifacts-credprovider.sh | bash

WORKDIR /src
COPY ["NuGet.config", "."]
COPY ["src/Application/Application.csproj", "src/Application/"]
COPY ["src/Domain/Domain.csproj", "src/Domain/"]
COPY ["src/Infrastructure/Infrastructure.csproj", "src/Infrastructure/"]

RUN dotnet restore "src/Application/Application.csproj"
COPY . .
WORKDIR "/src/src/Application"
RUN dotnet build "Application.csproj" -c $configuration --no-restore

FROM build AS publish
ARG configuration=Release
RUN dotnet publish "Application.csproj" -c $configuration -o /app/publish --no-build

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "UtahPublicEd.StudentBackpack.Application.dll"]
